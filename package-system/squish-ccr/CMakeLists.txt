#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# CMake definition for squish-ccr 2.00 alpha2
cmake_minimum_required(VERSION 3.17)

project(squish-ccr)

set(SQUISH_SOURCE_FILES 
    alpha.cpp
    alphanormalfit.cpp
    bitoneblock.cpp
    bitoneclusterfit.cpp
    bitonefit.cpp
    bitonenormalfit.cpp
    bitonerangefit.cpp
    bitoneset.cpp
    colourblock.cpp
    colourclusterfit.cpp
    colourfit.cpp
    colournormalfit.cpp
    colourrangefit.cpp
    colourset.cpp
    hdrblock.cpp
    hdrfit.cpp
    hdrindexfit.cpp
    hdrrangefit.cpp
    hdrset.cpp
    hdrsinglefit.cpp
    hdrsinglesnap.cpp
    maths.cpp
    paletteblock.cpp
    palettechannelfit.cpp
    paletteclusterfit.cpp
    palettefit.cpp
    paletteindexfit.cpp
    palettenormalfit.cpp
    paletterangefit.cpp
    paletteset.cpp
    coloursinglefit.cpp
    coloursinglesnap.cpp
    palettesinglefit.cpp
    palettesinglesnap.cpp
    simd.cpp
    squish.cpp
)

set(SQUISH_HEADER_FILES
    alpha.h
    alphanormalfit.h
    bitoneblock.h
    bitoneclusterfit.h
    bitonefit.h
    bitonenormalfit.h
    bitonerangefit.h
    bitoneset.h
    colourblock.h
    colourclusterfit.h
    colourfit.h
    colournormalfit.h
    colourrangefit.h
    colourset.h
    config.h
    helpers.h
    hdrblock.h
    hdrfit.h
    hdrindexfit.h
    hdrrangefit.h
    hdrset.h
    hdrsinglefit.h
    hdrsinglesnap.h
    maths.h
    paletteblock.h
    palettechannelfit.h
    paletteclusterfit.h
    palettefit.h
    paletteindexfit.h
    palettenormalfit.h
    paletterangefit.h
    paletteset.h
    simd.h
    simd_float.h
    simd_sse.h
    simd_ve.h
    coloursinglefit.h
    coloursinglesnap.h
    palettesinglefit.h
    palettesinglesnap.h
    squish.h
)
set(SQUISH_INLINE_FILES
    bitoneclusterfit.inl
    coloursinglelookup.inl
    palettesinglelookup.inl
)

set(SQUISH_PUBLIC_INCLUDE_FILES
    squish.h
    config.h
    coloursinglelookup_ccr.inl
    coloursinglelookup_ccr_vector.inl
    degeneracy_ccr.inl
)

add_library(squish-ccr SHARED ${SQUISH_SOURCE_FILES} ${SQUISH_HEADER_FILES} ${SQUISH_INLINE_FILES})
target_include_directories(squish-ccr PRIVATE ${CMAKE_CURRENT_LIST_DIR})
target_compile_definitions(squish-ccr PRIVATE SQUISH_USE_SSE=2 SQUISH_USE_CPP SQUISH_USE_CCR)

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(squish-ccr PRIVATE -msse2 -Wno-unused-value)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_definitions(squish-ccr PRIVATE NDEBUG USE_CPP)
    #target_compile_definitions(squish-ccr PRIVATE _ALLOW_ITERATOR_DEBUG_LEVEL_MISMATCH _ALLOW_RUNTIME_LIBRARY_MISMATCH)
endif()

set_target_properties(squish-ccr
    PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/lib/"
        PUBLIC_HEADER "${SQUISH_PUBLIC_INCLUDE_FILES}"
)

include(GNUInstallDirs)

install(TARGETS squish-ccr
        PUBLIC_HEADER
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/squish-ccr"
        LIBRARY
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
)