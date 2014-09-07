cmake_minimum_required(VERSION 2.8)
project(GooFit)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")
include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR}/thrust)


find_package(CUDA)
find_package(OpenMP)
find_package(ROOT REQUIRED COMPONENTS RooFitCore RooFit Hist Minuit Minuit2 MathCore Graf Graf3d Gpad)

#set up module includes
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/PDFs)
set(GOOFIT_MAJOR_VERSION 0)
set(GOOFIT_MINOR_VERSION 1)
set(GOOFIT_PATCH_VERSION 0)

set(GOOFIT_VERSION      
  ${GOOFIT_MAJOR_VERSION}.${GOOFIT_MINOR_VERSION}.${GOOFIT_PATCH_VERSION})


#user settable variables section
#set(INSTALL_LIB_DIR lib CACHE PATH "Installation directory for libraries")
#set(INSTALL_BIN_DIR bin CACHE PATH "Installation directory for executables")
#set(INSTALL_INCLUDE_DIR include CACHE PATH)
set(GOOFIT_THRUST_BACKEND "CUDA" CACHE STRING "which backend to use for thrust, either \"CUDA\" or \"OPENMP\"")


if(NOT ${GOOFIT_THRUST_BACKEND} MATCHES "OPENMP")
    if(NOT ${GOOFIT_THRUST_BACKEND} MATCHES "CUDA")
        message(FATAL_ERROR "Invalid value for \"GOOFIT_THRUST_BACKEND\", only \"CUDA\" or \"OPENMP\" are allowed")
    endif()
endif()

if(${GOOFIT_THRUST_BACKEND} MATCHES "OPENMP")
    if(${OPENMP_FOUND})
        set(GOOFIT_BACKEND_OPENMP ON)
    else()
        message(FATAL_ERROR "Backend \"OPENMP\" was selected but OpenMP installation could not be found")
    endif()
endif()

if(${GOOFIT_THRUST_BACKEND} MATCHES "CUDA")
    if(${CUDA_FOUND})
	include_directories(${CUDA_INCLUDE_DIRS})
        set(GOOFIT_BACKEND_CUDA ON)
    else()
        message(FATAL_ERROR "Backend \"CUDA\" was selected but CUDA-SDK installation could not be found")
    endif()
endif()

message(STATUS "Building GooFit using ${GOOFIT_THRUST_BACKEND} backend")

set(CXX_STD "-std=c++11")
set(CXX_STDLIB "")
set(NVCC_STDLIB "")
if(${APPLE})
    set(MACOSX_RPATH ON)
    set(CXX_STDLIB "-stdlib=libstdc++")
    set(NVCC_STDLIB -Xcompiler -stdlib=libstdc++)
    message(STATUS "Building for Mac OS X, selecting c++11 with stdlib stdc++")

    if(${GOOFIT_BACKEND_CUDA})
       set(CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
    endif()
endif(${APPLE})

 if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
   message( STATUS "Building for Linux, selecting c++11" )
 endif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_STD} -pedantic -Wall -Wextra -fPIC -Wno-unused-parameter")
set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};-I${CMAKE_CURRENT_SOURCE_DIR}/thrust;${NVCC_STDLIB})
set(CMAKE_EXE_LINKER_FLAGS "${CXX_STDLIB} ${CXX_STD}")



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
    "${ROOT_INCLUDE_DIRS}"
    "${PROJECT_SOURCE_DIR}"   # to find foo/foo.h
    "${PROJECT_BINARY_DIR}")  # to find foo/config.h

if(NOT ${CUDA_FOUND})
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/fakecuda)
endif()


file(GLOB Functors ${CMAKE_CURRENT_SOURCE_DIR}/*.cu ${CMAKE_CURRENT_SOURCE_DIR}/PDFs/*.cu)
file(GLOB CXXCode  ${CMAKE_CURRENT_SOURCE_DIR}/*.cc ${CMAKE_CURRENT_SOURCE_DIR}/PDFs/*.cc)

#filter out MINUIT version dependant .cc/.hh
LIST(REMOVE_ITEM CXXCode
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit1.hh
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit1.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit2.hh
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit2.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit3.hh
    ${CMAKE_CURRENT_SOURCE_DIR}/FitManagerMinuit3.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/GenVoigtian.cc)

#flag magic
set(ADDITIONAL_CXXFLAGS "${OpenMP_CXX_FLAGS} -DHAVE_ROOT=1 -DGOOFIT_THRUST_BACKEND_${GOOFIT_THRUST_BACKEND}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ADDITIONAL_CXXFLAGS}")

message(STATUS "ADDITIONAL FLAGS ${ADDITIONAL_CXXFLAGS}")
message(STATUS "FLAG NORMAL ${CMAKE_CXX_FLAGS}")
message(STATUS "FLAG DEBUG ${CMAKE_CXX_FLAGS_DEBUG}")
message(STATUS "FLAG RELEASE ${CMAKE_CXX_FLAGS_RELEASE}")

if(${GOOFIT_BACKEND_CUDA})
    set(CUDA_ARCH_FLAGS -arch=sm_20)
    set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};${CUDA_ARCH_FLAGS};-Xcompiler -fpic;-Xcompiler ${ADDITIONAL_CXXFLAGS})
    if(CMAKE_BUILD_TYPE MATCHES Release)
    	set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};-O3)
    	message(STATUS "compiling in release mode")
    endif()

    set(CUDA_SEPARABLE_COMPILATION ON)
    set(CUDA_HOST_COMPILATION_CPP ON)
    set(CUDA_PROPAGATE_HOST_FLAGS OFF)

    cuda_add_library(GooFit SHARED ${CXXCode} ${Functors})
endif()

if(${GOOFIT_BACKEND_OPENMP})
    set_source_files_properties(${Functors}
                                PROPERTIES
                                LANGUAGE CXX
                                COMPILE_FLAGS "${CMAKE_CXX_FLAGS} -x c++")
    add_definitions(-DTHRUST_DEVICE_SYSTEM=THRUST_DEVICE_BACKEND_OMP)
    add_library(GooFit SHARED ${CXXCode} ${Functors})
endif()

target_link_libraries(GooFit ${ROOT_LIBRARIES} ${ROOFIT_LIBRARIES})

if(${CUDA_FOUND})
        #add_subdirectory(examples)
else()
	message(WARNING "Deactivating examples since their camke files don't support openmp, yet")
endif()
#add_subdirectory(rootstuff)

export(PACKAGE GooFit)


