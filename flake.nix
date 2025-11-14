{
  description = "CrealityPrint - open source 3D printing slicer";

  # Nixpkgs inputs for different systems
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Common dependencies across all platforms
        commonDeps = with pkgs; [
          # Build tools
          cmake
          ninja
          git
          wget
          curl
          pkg-config
          file

          # Essential libraries
          boost
          openssl
          curl.dev
          glew
          glfw
          eigen

          # Image and multimedia
          libpng
          libjpeg
          libtiff
          libwebp

          # Audio/video processing (for timelapses)
          ffmpeg

          # Computer vision
          opencv

          # CAD/Geometry kernels
          opencascade-occt

          # 3D model loading
          assimp

          # MQTT client for IoT communication
          paho-mqtt-cpp
          paho-mqtt-c

          
          # Compression
          zlib
          libzip
          xz
          bzip2
          libdeflate

          # Audio processing
          alsa-lib

          # Geometry and math
          openvdb
          cgal
          gmp
          mpfr
          openexr
          ilmbase

          # Threading
          tbb

          # Serialization
          cereal

          # Non-linear optimization
          nlopt

          # Font rendering
          freetype

          # System integration
          dbus
          libsecret
          udev

          # Build utilities
          autoconf
          automake
          libtool
          texinfo
          m4
          patch
        ];

        # Linux-specific dependencies
        linuxDeps = with pkgs; commonDeps ++ [
          # wxWidgets and GTK3
          wxGTK32
          gtk3
          gtkmm3
          pango
          atk
          gdk-pixbuf
          cairo

          # Additional Linux libraries
          glib
          extra-cmake-modules
          systemd

          # OpenGL support
          libGLU
          libGL

          # Web rendering
          webkitgtk_4_1

          # Mesa for OpenGL offscreen rendering
          mesa
          wayland
          wayland-protocols

          # Fontconfig
          fontconfig

          # Audio and multimedia
          libpulseaudio
          speex
          lerc
          x264

          # GStreamer for multimedia processing
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-libav

          # X11 support
          xorg.libX11
          xorg.libXext
          xorg.libXrandr
          xorg.libXinerama
          xorg.libXcursor
          xorg.libXi
        ];

        # Darwin-specific dependencies
        darwinDeps = with pkgs; commonDeps ++ [
          # macOS-specific libraries
          darwin.apple_sdk.frameworks.OpenGL
          darwin.apple_sdk.frameworks.Foundation
          darwin.apple_sdk.frameworks.AppKit
          darwin.apple_sdk.frameworks.CoreGraphics
          darwin.apple_sdk.frameworks.CoreText
          darwin.apple_sdk.frameworks.Carbon
          darwin.apple_sdk.frameworks.Cocoa
          darwin.apple_sdk.frameworks.QuartzCore
          darwin.apple_sdk.frameworks.CoreAudio
          darwin.apple_sdk.frameworks.AudioUnit
          darwin.apple_sdk.frameworks.CoreVideo
          darwin.apple_sdk.frameworks.CoreMedia
          darwin.apple_sdk.frameworks.AVFoundation

          # macOS package management
          darwin.apple_sdk.frameworks.Security
        ];

        # Select appropriate dependencies based on system
        deps = if pkgs.stdenv.isLinux then linuxDeps
               else if pkgs.stdenv.isDarwin then darwinDeps
               else commonDeps;

        # Development shell with all dependencies
        devShell = pkgs.mkShell {
          buildInputs = deps;

          nativeBuildInputs = with pkgs; [
            # Additional build tools
            git-lfs
            ccache
            python3
            python3Packages.pip

            # Code formatting and analysis
            clang-tools
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            cppcheck
          ];

          shellHook = ''
            # Set environment variables
            export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
            export CMAKE_GENERATOR=Ninja

            # Ensure git-lfs is available for large files
            if command -v git-lfs >/dev/null 2>&1; then
              echo "Git LFS is available"
            else
              echo "Warning: git-lfs not found, you may need it for large files"
            fi

            # Print helpful information
            echo "CrealityPrint development environment ready!"
            echo ""
            echo "Available commands:"
            echo "  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release  - Configure build"
            echo "  cmake --build build --target CrealityPrint       - Build main application"
            echo "  cmake --build build --target CrealityPrint_profile_validator - Build profile validator"
            echo "  ./run_gettext.sh                                - Generate translation files"
            echo ""
            echo "For first-time setup, you may need to:"
            echo "  1. git lfs pull  (pull large files)"
            echo "  2. ./BuildLinux.sh -u  (if on Linux and want to use original script)"
          '';
        };

        # Package build configuration
        crealityPrint = pkgs.stdenv.mkDerivation {
          pname = "crealityprint";
          version = "6.0.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            git
            pkg-config
            patch
            python3
          ];

          buildInputs = deps;

          preConfigure = ''
            # Pull git lfs files if needed
            if [ -d .git ]; then
              git lfs pull || echo "Git LFS pull failed, continuing..."
            fi

            # Set version in version.inc
            if [ -f version.inc ]; then
              sed -i "s/+UNKNOWN/_$(date '+%F')/" version.inc
            fi
          '';

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DSLIC3R_STATIC=0"
            "-DSLIC3R_GTK=3"
            "-DORCA_TOOLS=ON"
            "-DGENERATE_ORCA_HEADER=0"
            "-DENABLE_BREAKPAD=OFF"
            "-DBBL_RELEASE_TO_PUBLIC=1"
            "-DUPDATE_ONLINE_MACHINES=1"
            "-DBBL_INTERNAL_TESTING=0"
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
          ];

          buildPhase = ''
            runHook preBuild
            cmake --build . --target CrealityPrint
            cmake --build . --target CrealityPrint_profile_validator
            runHook postBuild
          '';

          postBuild = ''
            # Generate translation files
            if [ -f ./run_gettext.sh ]; then
              chmod +x ./run_gettext.sh
              ./run_gettext.sh
            fi
          '';

          installPhase = ''
            runHook preInstall

            # Install main executable
            mkdir -p $out/bin
            cp build/src/CrealityPrint $out/bin/

            # Install profile validator
            cp build/src/CrealityPrint_profile_validator $out/bin/

            # Install resources
            mkdir -p $out/share/CrealityPrint
            cp -r resources/* $out/share/CrealityPrint/

            # Install desktop file
            mkdir -p $out/share/applications
            cp src/platform/unix/CrealityPrint.desktop $out/share/applications/

            # Install icons
            mkdir -p $out/share/icons/hicolor
            for size in 32 128 192; do
              mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
              cp "resources/images/CrealityPrint_''${size}px.png" "$out/share/icons/hicolor/''${size}x''${size}/apps/CrealityPrint.png"
            done

            # Copy any required runtime libraries
            if [ -d build/src ]; then
              find build/src -name "*.so*" -exec cp {} $out/bin/ \; 2>/dev/null || true
            fi

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Open source 3D printing slicer";
            longDescription = ''
              CrealityPrint is an open-source slicer for FDM printers, forked from Orca Slicer.
              Features include auto-calibration, sandwich mode, polyholes conversion, Klipper support,
              and granular controls for advanced users.
            '';
            homepage = "https://github.com/CrealityOfficial/CrealityPrint";
            license = licenses.agpl3Only;
            platforms = platforms.linux ++ platforms.darwin;
            mainProgram = "CrealityPrint";
          };
        };

      in
      {
        # Development shell
        devShells.default = devShell;

        # Package
        packages.default = crealityPrint;

        # App image package (Linux only)
        packages.appImage = with pkgs; (pkgs.appimageTools.wrapType2 {
          name = "crealityprint";
          src = crealityPrint;
        });
      }
    );
}
