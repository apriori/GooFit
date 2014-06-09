add_definitions(${ROOT_DEFINITIONS})

if(${ROOT_FOUND})
    list(APPEND CUDA_NVCC_FLAGS -DHAVE_ROOT=1)
    message(STATUS "Building examples with systems provided ROOT version ${ROOT_VERSION}")
endif()
