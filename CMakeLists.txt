cmake_minimum_required(VERSION 3.11)

set(CMAKE_C_STANDARD 11)

project(RosBE LANGUAGES C CXX)

find_package(Patch REQUIRED)
include(ExternalProject)

set(SOURCE_DIR "${CMAKE_SOURCE_DIR}/sources" CACHE FILEPATH "Where to find/download archives")

include(prepare-source.cmake)

set(CMAKE_INSTALL_PREFIX "/usr/local/RosBE" "" CACHE INTERNAL "")

set(_install_dir "${CMAKE_INSTALL_PREFIX}")

ExternalProject_Add(cmake
    SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/cmake
    CMAKE_ARGS "-DCMAKE_INSTALL_PREFIX:STRING=${_install_dir}")

function(add_toolchain _target)
    set(_prefix <INSTALL_DIR>)
    set(_sysroot <INSTALL_DIR>/${_target})

    ExternalProject_Add(${_target}-binutils
        SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/binutils
        INSTALL_DIR ${_install_dir}
        CONFIGURE_COMMAND <SOURCE_DIR>/configure
            --target=${_target}
            --prefix=${_prefix}
            --with-sysroot=${_sysroot}
            --disable-multilib
            --disable-werror
            --enable-lto
            --enable-plugins
        BUILD_COMMAND   $(MAKE)
        INSTALL_COMMAND $(MAKE) install
        EXCLUDE_FROM_ALL TRUE
    )

    ExternalProject_Add(${_target}-headers
        SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/mingw-w64/mingw-w64-headers
        INSTALL_DIR ${_install_dir}
        DEPENDS ${_target}-binutils
        CONFIGURE_COMMAND <SOURCE_DIR>/configure
            --host=${_target}
            --prefix=${_sysroot}
        BUILD_COMMAND   $(MAKE)
        INSTALL_COMMAND $(MAKE) install
                COMMAND ${CMAKE_COMMAND} -E create_symlink . ${_sysroot}/mingw
        EXCLUDE_FROM_ALL TRUE
    )

    ExternalProject_Add(${_target}-gcc
        SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/gcc
        INSTALL_DIR ${_install_dir}
        DEPENDS ${_target}-binutils ${_target}-headers
        CONFIGURE_COMMAND <SOURCE_DIR>/configure
            --target=${_target}
            --prefix=${_prefix}
            --with-sysroot=${_sysroot}
            --with-pkgversion=RosBE
            --enable-languages=c,c++
            --enable-fully-dynamic-string
            --enable-checking=release
            --enable-version-specific-runtime-libs
            --enable-plugins
            --disable-shared
            --disable-multilib
            --disable-nls
            --disable-werror
            --with-gnu-ld
            --with-gnu-as
            && echo "MAKEINFO = :" >> <BINARY_DIR>/Makefile
        BUILD_COMMAND   $(MAKE)
        INSTALL_COMMAND $(MAKE) install
    )

    ExternalProject_Add_Step(${_target}-gcc stage_1
        DEPENDEES configure
        WORKING_DIRECTORY <BINARY_DIR>
        COMMAND $(MAKE) all-gcc
        COMMAND $(MAKE) install-gcc
    )
    ExternalProject_Add_StepTargets(${_target}-gcc stage_1)

    ExternalProject_Add(${_target}-crt
        SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/mingw-w64/mingw-w64-crt
        INSTALL_DIR ${_install_dir}
        DEPENDS ${_target}-gcc-stage_1
        CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env "PATH=<INSTALL_DIR>/bin:$ENV{PATH}"
            <SOURCE_DIR>/configure
                --host=${_target}
                --prefix=${_sysroot}
                --with-sysroot=${_sysroot}
        BUILD_COMMAND     ${CMAKE_COMMAND} -E env "PATH=<INSTALL_DIR>/bin:$ENV{PATH}" 
            $(MAKE)
        INSTALL_COMMAND   ${CMAKE_COMMAND} -E env "PATH=<INSTALL_DIR>/bin:$ENV{PATH}" 
            $(MAKE) install
        EXCLUDE_FROM_ALL TRUE
    )

    ExternalProject_Add_StepDependencies(${_target}-gcc build ${_target}-crt)

endfunction()

add_toolchain(i686-w64-mingw32)
#add_toolchain(x86_64-w64-mingw32)
