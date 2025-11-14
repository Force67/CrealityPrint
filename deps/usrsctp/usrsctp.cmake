set(USRSCTP_VERSION 0.9.4.0)
set(USRSCTP_ARCHIVE_URL "https://github.com/sctplab/usrsctp/archive/refs/tags/${USRSCTP_VERSION}.tar.gz")
set(USRSCTP_ARCHIVE_HASH "SHA256=e7b8f908d71dc69c9a2bf55d609e8fdbb2fa7cc647f8b23a837d36a05c59cd77")

orcaslicer_add_cmake_project(usrsctp
    URL "${USRSCTP_ARCHIVE_URL}"
    URL_HASH ${USRSCTP_ARCHIVE_HASH}
    CMAKE_ARGS
        -Dsctp_werror=0
        -Dsctp_build_programs=0
        -Dsctp_build_shared_lib=1
        -Dsctp_debug=0
        -Dsctp_invariants=0
)
