CC = g++
CFLAGS = -Wall -lm
#you might check the libs here, cf your glfw installation
GLFLAGS   = -lglfw -lXxf86vm -lXext -lX11 -lGLU  -lGL -lpthread 

host_window_t: host_window_t.cpp host_window.h
	$(CC) $(CFLAGS) $< -o $@ $(GLFLAGS) 


.PHONY: clean doc

doc: 
	doxygen Doxyfile

clean:
	rm -f *_t 
