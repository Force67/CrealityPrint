set(OPUS_VERSION 1.5.2)
set(OPUS_ARCHIVE_URL "https://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz")
set(OPUS_ARCHIVE_HASH "SHA256=65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1")

set(_opus_env
    CC=${CMAKE_C_COMPILER}
    CXX=${CMAKE_CXX_COMPILER}
    AR=${CMAKE_AR}
    RANLIB=${CMAKE_RANLIB}
    CFLAGS=-fPIC
)

ExternalProject_Add(dep_opus
    URL "${OPUS_ARCHIVE_URL}"
    URL_HASH ${OPUS_ARCHIVE_HASH}
    DOWNLOAD_DIR ${DEP_DOWNLOAD_DIR}/Opus
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E env ${_opus_env}
        ./configure
            --prefix=${DESTDIR}
            --disable-shared
            --enable-static
    BUILD_IN_SOURCE ON
    BUILD_COMMAND make -j${NPROC}
    INSTALL_COMMAND make install
)
