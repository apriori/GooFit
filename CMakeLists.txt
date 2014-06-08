cmake_minimum_required(VERSION 2.8)
project(GooFit)
#set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

find_package(CUDA REQUIRED)
#find_package(MPI REQUIRED)
#include(FindMPI)
include(FindCUDA)

#set up module includes
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/PDFs)
#include_directories(${MPI_CXX_INCLUDE_PATH})
include_directories(${CUDA_INCLUDE_DIRS})

set(CUDA_NVCC_FLAGS -arch=sm_20;-Xcompiler -fpic)
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

message(STATUS "mpi include dir ${MPI_CXX_INCLUDE_PATH}")

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
#add_subdirectory(examples)

#export(TARGETS foo bar
#      FILE "${PROJECT_BINARY_DIR}/FooBarTargets.cmake")

export(PACKAGE GooFit)

# Create the FooBarConfig.cmake and FooBarConfigVersion files
file(RELATIVE_PATH REL_INCLUDE_DIR "${INSTALL_CMAKE_DIR}"
       "${INSTALL_INCLUDE_DIR}")
   # ... for the build tree
set(CONF_INCLUDE_DIRS "${PROJECT_SOURCE_DIR}" "${PROJECT_BINARY_DIR}")
#configure_file(GooFitConfig.cmake.in
#         "${PROJECT_BINARY_DIR}/GooFitConfig.cmake" @ONLY)

     # ... for the install tree
set(CONF_INCLUDE_DIRS "\${GOOFIT_CMAKE_DIR}/${REL_INCLUDE_DIR}")
#configure_file(GooFitConfig.cmake.in
#       "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/GooFitConfig.cmake" @ONLY)
       
# ... for both
#configure_file(GooFitConfigVersion.cmake.in
#    "${PROJECT_BINARY_DIR}/GooFitConfigVersion.cmake" @ONLY)
      
# Install the GooFitConfig.cmake and GooFitConfigVersion.cmake
#install(FILES
#   "${PROJECT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/GooFitConfig.cmake"
#     "${PROJECT_BINARY_DIR}/GooFitConfigVersion.cmake"
#       DESTINATION "${INSTALL_CMAKE_DIR}" COMPONENT dev)
    
# Install the export set for use with the install-tree
#install(EXPORT GooFitTargets DESTINATION
#     "${INSTALL_CMAKE_DIR}" COMPONENT dev)
     
#configure_file(config.h.in "${CMAKE_CURRENT_BINARY_DIR}/config.h" @ONLY)

file(GLOB Functors ${CMAKE_CURRENT_BINARY_DIR}/*.cu ${CMAKE_CURRENT_BINARY_DIR}/PDFs/*.cu)

file(GLOB CXXCode ${CMAKE_CURRENT_BINARY_DIR}/*.hh ${CMAKE_CURRENT_BINARY_DIR}/*.cc ${CMAKE_CURRENT_BINARY_DIR}/PDFs/*.hh ${CMAKE_CURRENT_BINARY_DIR}/PDFs/*.cc)

#filter out MINUIT version dependant .cc/.hh
LIST(REMOVE_ITEM CXXCode
    ${CMAKE_CURRENT_BINARY_DIR}/FitManagerMinuit1.hh
    ${CMAKE_CURRENT_BINARY_DIR}/FitManagerMinuit1.cc
    ${CMAKE_CURRENT_BINARY_DIR}/FitManagerMinuit2.hh
    ${CMAKE_CURRENT_BINARY_DIR}/FitManagerMinuit2.cc
    ${CMAKE_CURRENT_BINARY_DIR}/FitManagerMinuit3.hh
    ${CMAKE_CURRENT_BINARY_DIR}/FitManagerMinuit3.cc
    ${CMAKE_CURRENT_BINARY_DIR}/GenVoigtian.cc)


#cuda_compile(CUDA_O ${Functors} config.h.in)
#add_library(GooFit SHARED ${CUDA_O} config.h.in)
cuda_compile(CUDA_O ${Functors})
add_library(GooFit SHARED ${CUDA_O} ${CXXCode})
target_link_libraries(GooFit ${MPI_LIBRARIES})

#set_target_properties(foo PROPERTIES
#  PUBLIC_HEADER "foo.h;${CMAKE_CURRENT_BINARY_DIR}/config.h")
 
#install(TARGETS foo
  # IMPORTANT: Add the foo library to the "export-set"
  #  EXPORT FooBarTargets
  # RUNTIME DESTINATION "${INSTALL_BIN_DIR}" COMPONENT bin
  # LIBRARY DESTINATION "${INSTALL_LIB_DIR}" COMPONENT shlib
  # PUBLIC_HEADER DESTINATION "${INSTALL_INCLUDE_DIR}/foo"
  #    COMPONENT dev)
#The file FooBar/bar/CMakeLists.txt is even shorter:
#add_executable(bar bar.c)
 
#target_link_libraries(bar foo)
 
#install(TARGETS bar
  # IMPORTANT: Add the bar executable to the "export-set"
  #  EXPORT FooBarTargets
  # RUNTIME DESTINATION "${INSTALL_BIN_DIR}" COMPONENT bin)     
