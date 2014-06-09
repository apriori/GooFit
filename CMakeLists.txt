cmake_minimum_required(VERSION 2.8)
project(GooFit)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")
find_package(CUDA REQUIRED)

#set up module includes
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/PDFs)
include_directories(${CUDA_INCLUDE_DIRS})

set(CUDA_ARCH_FLAGS -arch=sm_20)
set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};${CUDA_ARCH_FLAGS};-Xcompiler -fpic)
set(CUDA_SEPARABLE_COMPILATION ON)
set(CUDA_HOST_COMPILER g++)

set(GOOFIT_MAJOR_VERSION 0)
set(GOOFIT_MINOR_VERSION 1)
set(GOOFIT_PATCH_VERSION 0)

set(GOOFIT_VERSION      
  ${GOOFIT_MAJOR_VERSION}.${GOOFIT_MINOR_VERSION}.${GOOFIT_PATCH_VERSION})

#set(INSTALL_LIB_DIR lib CACHE PATH "Installation directory for libraries")
#set(INSTALL_BIN_DIR bin CACHE PATH "Installation directory for executables")
#set(INSTALL_INCLUDE_DIR include CACHE PATH)

set(INSTALL_CMAKE_DIR ${DEF_INSTALL_CMAKE_DIR} CACHE PATH
      "Installation directory for CMake files")

# Make relative paths absolute (needed later on)
foreach(p LIB BIN INCLUDE CMAKE)
    set(var INSTALL_${p}_DIR)
    if(NOT IS_ABSOLUTE "${${var}}")
        set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
    endif()
endforeach()

include_directories(
    "${PROJECT_SOURCE_DIR}"   # to find foo/foo.h
    "${PROJECT_BINARY_DIR}")  # to find foo/config.h

#add_subdirectory(rootstuff)
add_subdirectory(examples)

export(PACKAGE GooFit)


file(GLOB Functors ${CMAKE_CURRENT_SOURCE_DIR}/*.cu ${CMAKE_CURRENT_SOURCE_DIR}/PDFs/*.cu)
file(GLOB CXXCode ${CMAKE_CURRENT_SOURCE_DIR}/*.hh ${CMAKE_CURRENT_SOURCE_DIR}/*.cc ${CMAKE_CURRENT_SOURCE_DIR}/PDFs/*.hh ${CMAKE_CURRENT_SOURCE_DIR}/PDFs/*.cc)

#filter out MINUIT version dependant .cc/.hh
LIST(REMOVE_ITEM CXXCode
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit1.hh
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit1.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit2.hh
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit2.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit3.hh
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit3.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/GenVoigtian.cc)


cuda_add_library(GooFit SHARED ${CXXCode} ${Functors})

