#pragma once

#include <GLFW/glfw3.h>
namespace draw
{
void error_callback( int error, const char* description)
{
    std::cerr << description<<std::endl;
}

void WindowResize( GLFWwindow* window_, int w, int h)
{
    // map coordinates to the whole window
    glViewport( 0, 0, (GLsizei) w, h);
}
void key_callback( GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if( key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose( window, GL_TRUE);
}

/**
 * @brief Convenience function that inits glfw, opens a window and makes it the current context
 *
 * Furthermore it sets standard window error, resize and key callbacks. 
 * @param width width of the window to open
 * @param height height of the window to open
 * @param title initial title of the window
 *
 * @return pointer to the opaque GLFW window type
 */
GLFWwindow* glfwInitAndCreateWindow(int width, int height, const char* title)
{
    // create window and OpenGL context bound to it
    glfwSetErrorCallback( error_callback);
    if( !glfwInit()) { std::cerr << "ERROR: glfw couldn't initialize.\n";}
    GLFWwindow* window_ = glfwCreateWindow( width, height, title, 0, 0);
    if( !window_){std::cerr << "ERROR: glfw couldn't open window_\n"; glfwTerminate();}
    glfwMakeContextCurrent( window_);
    glfwSetWindowSizeCallback( window_, WindowResize);
    glfwSetKeyCallback( window_, key_callback);
    int major, minor, rev;
    glfwGetVersion( &major, &minor, &rev);
    std::cout << "Using GLFW version   "<<major<<"."<<minor<<"."<<rev<<"\n";
    std::cout << "Using OpenGL version "
              << glfwGetWindowAttrib( window_, GLFW_CONTEXT_VERSION_MAJOR)<<"."
              << glfwGetWindowAttrib( window_, GLFW_CONTEXT_VERSION_MINOR)<<"\n";
    return window_;
}

}//namespace draw
