cmake_minimum_required(VERSION 2.8)
project(addition)

find_package(ROOT REQUIRED COMPONENTS Hist Minuit Minuit2 MathCore Graf Graf3d Gpad)
include(../examplesbase.cmake)

cuda_include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../../ ${ROOT_INCLUDE_DIRS})
cuda_add_executable(addition addition.cu)
target_link_libraries(addition GooFit ${ROOT_LIBRARIES})
