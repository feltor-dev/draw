
#include <iostream>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include "../toefl/inc/dg/timer.cuh"
#include "device_window.cuh"
/**
 * @brief Functor returning a gaussian
 * \f[
   f(x,y) = Ae^{-(\frac{(x-x_0)^2}{2\sigma_x^2} + \frac{(y-y_0)^2}{2\sigma_y^2}} 
   \f]
 */
struct Gaussian
{
    /**
     * @brief Functor returning a gaussian
     *
     * @param x0 x-center-coordinate
     * @param y0 y-center-coordinate
     * @param sigma_x x - variance
     * @param sigma_y y - variance 
     * @param amp Amplitude
     */
    Gaussian( float x0, float y0, float sigma_x, float sigma_y, float amp)
        : x00(x0), y00(y0), sigma_x(sigma_x), sigma_y(sigma_y), amplitude(amp){}
    /**
     * @brief Return the value of the gaussian
     *
     * \f[
       f(x,y) = Ae^{-(\frac{(x-x_0)^2}{2\sigma_x^2} + \frac{(y-y_0)^2}{2\sigma_y^2}} 
       \f]
     * @param x x - coordinate
     * @param y y - coordinate
     *
     * @return gaussian
     */
    float operator()(float x, float y)
    {
        return  amplitude*
                   exp( -((x-x00)*(x-x00)/2./sigma_x/sigma_x +
                          (y-y00)*(y-y00)/2./sigma_y/sigma_y) );
    }
  private:
    float  x00, y00, sigma_x, sigma_y, amplitude;

};

const unsigned Nx = 7000, Ny = 4000;
const float lx = 2., ly = 1.;
const float hx = lx/(float)Nx, hy = ly/(float)Ny;

int main()
{
    //Create Window and set window title
    draw::DeviceWindow w( 800, 400);
    // generate a vector on the grid to visualize 
    Gaussian g( 1.2, 0.3, .1, .1, 1);
    thrust::host_vector<float> visual(Nx*Ny);
    for(unsigned i=0; i<Ny; i++)
        for( unsigned j=0; j<Nx; j++)
            visual[i*Nx+j] = -g( (float)j*hx, (float)i*hy);
    thrust::device_vector<float> dvisual = visual;

    //create a colormap
    draw::ColorMapRedBlueExt colors( 1.);
    //set scale
    colors.scale() =  1.;

    int running = GL_TRUE;
    dg::Timer t;
    while (running)
    {
        w.title() << "Hello world\n";
        t.tic();
        w.draw( dvisual, Nx, Ny, colors);
        t.toc();
        std::cout << "Drawing took "<<t.diff()*1000.<<"ms\n";
        glfwWaitEvents();
        running = !glfwGetKey( GLFW_KEY_ESC) &&
                    glfwGetWindowParam( GLFW_OPENED);
    }

    return 0;
}
