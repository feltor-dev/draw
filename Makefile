CC = g++
NVCC = nvcc
INCLUDE = -I$(HOME)/include
CFLAGS = -Wall -lm -O3 -Wextra -pedantic
NVCCFLAGS = --compiler-options -Wall --compiler-options -Wextra -arch=native -O3
#you might check the libs here, cf your glfw installation
GLFLAGS =$$(pkg-config --static --libs glfw3) -lGL#glfw3 installation


all: host_window_t device_window_t

host_window_t: host_window_t.cpp host_window.h
	$(CC) $(CFLAGS) $< -o $@ $(GLFLAGS)  -g

device_window_t: device_window_t.cu device_window.cuh
	$(NVCC) $(NVCCFLAGS) $< -o $@ $(INCLUDE) $(GLFLAGS) -lGLEW -g

.PHONY: clean doc

doc:
	doxygen Doxyfile

clean:
	rm -f *_t
