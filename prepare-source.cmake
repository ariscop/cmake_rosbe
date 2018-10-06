

if(_sources_prepared)
    return()
endif()

set(_sources_prepared TRUE CACHE INTERNAL "")


function(prepare_source _name)
    cmake_parse_arguments(PARSE_ARGV 1 _src "" "VERSION;DOWNLOAD_URL;URL_HASH" "")

    if(${_name}_archive)
        return()
    endif()

    message(STATUS "Preparing ${_name}...")
    string(REPLACE <VERSION> ${_src_VERSION} url ${_src_DOWNLOAD_URL})
    get_filename_component(_archive ${url} NAME)
    # file checks the hash before downloading
    file(DOWNLOAD ${url} ${SOURCE_DIR}/${_archive} EXPECTED_HASH ${_src_URL_HASH})
    set(${_name}_archive ${SOURCE_DIR}/${_archive} CACHE INTERNAL "")
    set(${_name}_version ${_src_VERSION} CACHE INTERNAL "")
endfunction()

prepare_source(cmake VERSION 3.4.3
    DOWNLOAD_URL https://cmake.org/files/v3.4/cmake-3.4.3.tar.gz
    URL_HASH SHA256=b73f8c1029611df7ed81796bf5ca8ba0ef41c6761132340c73ffe42704f980fa)

prepare_source(binutils VERSION 2.24
    DOWNLOAD_URL https://ftp.gnu.org/gnu/binutils/binutils-<VERSION>.tar.bz2
    URL_HASH SHA256=e5e8c5be9664e7f7f96e0d09919110ab5ad597794f5b1809871177a0f0f14137)

prepare_source(gcc VERSION 4.7.4
    DOWNLOAD_URL https://ftp.gnu.org/gnu/gcc/gcc-<VERSION>/gcc-<VERSION>.tar.bz2
    URL_HASH SHA256=92e61c6dc3a0a449e62d72a38185fda550168a86702dea07125ebd3ec3996282)

prepare_source(gmp VERSION 5.0.5
    DOWNLOAD_URL https://ftp.gnu.org/gnu/gmp/gmp-<VERSION>.tar.bz2
    URL_HASH SHA256=1f588aaccc41bb9aed946f9fe38521c26d8b290d003c5df807f65690f2aadec9)

prepare_source(mpfr VERSION 3.0.1
    DOWNLOAD_URL https://ftp.gnu.org/gnu/mpfr/mpfr-<VERSION>.tar.bz2
    URL_HASH SHA256=e1977099bb494319c0f0c1f85759050c418a56884e9c6cef1c540b9b13e38e7f)

prepare_source(mpc VERSION 1.0.1
    DOWNLOAD_URL https://ftp.gnu.org/gnu/mpc/mpc-<VERSION>.tar.gz
    URL_HASH SHA256=ed5a815cfea525dc778df0cb37468b9c1b554aaf30d9328b1431ca705b7400ff)

prepare_source(mingw-w64 VERSION v3.3.0
    DOWNLOAD_URL https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-<VERSION>.tar.bz2
    URL_HASH SHA256=44764daa65f9adf562b0456e7b681c73c074dc6d1d3ae210f6000af0b641fcef)

function(extract_archive _name)
    message(STATUS "Extracting ${${_name}_archive}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xfJ ${${_name}_archive}
        ${ARGN})
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E rename ${_name}-${${_name}_version} ${_name}
        ${ARGN})

endfunction()

extract_archive(cmake)
extract_archive(binutils)
extract_archive(mingw-w64)
extract_archive(gcc)

function(apply_patch _path)
    foreach(patch ${ARGN})
        execute_process(
            COMMAND ${Patch_EXECUTABLE} -p1
            INPUT_FILE ${CMAKE_SOURCE_DIR}/patches/${patch}
            WORKING_DIRECTORY ${_path})
    endforeach()
endfunction()

apply_patch(${CMAKE_BINARY_DIR}/gcc
    gcc/0001-texi2pod.pl-Force-.pod-file-to-not-be-a-numbered-lis.patch
    gcc/0002-https-github.com-DragonFlyBSD-DPorts-commit-a680cc6e.patch
)

apply_patch(${CMAKE_BINARY_DIR}/cmake
    cmake/0001-Mark-this-as-ReactOS-modified-source.patch
    cmake/0002-Do-not-compute-architecture-specific-link-flags-when.patch
    cmake/0003-Improve-the-check-for-MSVC.patch
    cmake/0004-Don-t-let-CMake-map-SECTION-and-MERGE-link-flags-as-.patch
    cmake/0005-VS-PCH-flag-Yc-can-be-used-without-a-value-so-don-t-.patch
    cmake/0006-Empty-IncludePath-ReferencePath-LibraryPath-LibraryW.patch
    cmake/0007-Don-t-let-CMake-handle-CharacterSet.-Same-for-Precom.patch
)

extract_archive(gmp  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/gcc)
extract_archive(mpfr WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/gcc)
extract_archive(mpc  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/gcc)

