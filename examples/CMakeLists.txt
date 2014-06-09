cmake_minimum_required(VERSION 2.8)

file(GLOB sub-dir ${CMAKE_CURRENT_SOURCE_DIR}/*)
set(subdirlist)
foreach(dir ${sub-dir})
    if(IS_DIRECTORY ${dir})
        if(EXISTS "${dir}/CMakeLists.txt")
            add_subdirectory(${dir})
        endif()
    endif()
endforeach()

