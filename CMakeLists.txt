cmake_minimum_required( VERSION 3.26)

project( draw VERSION 1.3.0 LANGUAGES CXX)

# Incurs thrust dependence
option( DRAW_WITH_CUDA "Include a Cuda device version of the Renderer")
option( DRAW_BUILD_TESTS "Include tests")

add_library( draw INTERFACE "host_window.h" "colormap.h" "utility.h" )
add_library( draw::draw ALIAS draw)

target_compile_features(draw INTERFACE cxx_std_11)
# Make sure that #include "draw/host_window.h" can be found
target_include_directories(draw INTERFACE "${PROJECT_SOURCE_DIR}")

# Needs to be installed through system package manager
find_package( OpenGL REQUIRED)
find_package( glfw3 REQUIRED)

target_link_libraries( draw INTERFACE glfw)
target_link_libraries( draw INTERFACE OpenGL::GL)

# ============================================
# Set up compiler-specific flags

if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  # Currently raises too many warnings!
  set(DRAW_FLAGS_CXX
    "-Wall"
    "-Wextra"
  )
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  set(DRAW_FLAGS_CXX
    "/W4"
  )
else()
  set(DRAW_FLAGS_CXX "")
endif()

if( DRAW_BUILD_TESTS)
    add_executable( host_window_t "host_window_t.cpp")
    target_link_libraries( host_window_t PRIVATE draw)
    target_compile_options( host_window_t PRIVATE ${DRAW_FLAGS_CXX})
endif()

if( DRAW_WITH_CUDA)
  enable_language(CUDA)
  target_sources( draw INTERFACE "colormap.cuh" "device_window.cuh")
  # Add cccl
  include( cmake/CPM.cmake)
  CPMAddPackage( "gh:NVIDIA/cccl#v2.8.0")
  target_link_libraries(draw INTERFACE CCCL::CCCL)
  # Needs to be installed by system package manager
  find_package( GLEW REQUIRED)
  target_link_libraries(draw INTERFACE GLEW)
  target_compile_features(draw INTERFACE cuda_std_17)
  if( DRAW_BUILD_TESTS)
      add_executable( device_window_t "device_window_t.cu")
      target_link_libraries( device_window_t PRIVATE draw)
      target_compile_options( device_window_t PRIVATE ${DRAW_FLAGS_CXX})
  endif()
endif()
