cmake_minimum_required(VERSION 2.8)
project(chisquare)

find_package(ROOT REQUIRED COMPONENTS RooFitCore RooFit Hist Minuit Minuit2 MathCore Graf Graf3d Gpad)
include(../examplesbase.cmake)

cuda_include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../../ ${ROOT_INCLUDE_DIRS})
cuda_add_executable(chisquare chisquare.cu)
target_link_libraries(chisquare GooFit ${ROOT_LIBRARIES})
