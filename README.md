<hr>
<h3> Welcome to the DRAW project </h3>

The DRAW library helps
to realize a 2D visualisation from within a running simulation. 

<h4> Library dependencies </h4>

- the DRAW library relies on a working installation of OpenGL and [glfw-3](http://www.glfw.org/download.html)
  (If you experience linker problems with glfw be sure you add the correct 
   libraries for your system in the Makefile in the GLFLAGS/LIBS variable.)

- the device_window needs [CUDA](https://developer.nvidia.com/cuda-downloads) (and thrust which is included), 

<h4> Library documentation </h4>
The library comes with a documentation that can be 
created using [Doxygen]( http://www.stack.nl/~dimitri/doxygen/ ) via:
    doxygen Doxyfile 
that will create a doc/ subdirectory.
Open with
    firefox doc/html/index.html








