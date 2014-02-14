#pragma once

#include <GLFW/glfw3.h>
namespace draw
{
///@addtogroup Utility
///@{

/**
 * @brief Standard error callback function that prints error in error stream
 *
 * @param error error number 
 * @param description string containing description
 */
void error_callback( int error, const char* description)
{
    std::cerr << description<<std::endl;
}

/**
 * @brief Standard Resize functions, remaps the viewport to the whole window
 *
 * @param window Window identifiere
 * @param w width
 * @param h height
 */
void WindowResize( GLFWwindow* window, int w, int h)
{
    // map coordinates to the whole window
    glViewport( 0, 0, (GLsizei) w, h);
}
/**
 * @brief Key callback function, checks if ESC is pressed and registers window for closure
 *
 * @param window Window identifier
 * @param key key
 * @param scancode scancode
 * @param action action
 * @param mods mods
 */
void key_callback( GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if( key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose( window, GL_TRUE);
}

/**
 * @brief Convenience function that inits glfw, opens a window and makes it the current OpenGL context
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

///@}
}//namespace draw
