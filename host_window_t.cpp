#include <iostream>
#include <vector>

#include "host_window.h"

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
    Gaussian( double x0, double y0, double sigma_x, double sigma_y, double amp)
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
    double operator()(double x, double y)
    {
        return  amplitude*
                   exp( -((x-x00)*(x-x00)/2./sigma_x/sigma_x +
                          (y-y00)*(y-y00)/2./sigma_y/sigma_y) );
    }
  private:
    double  x00, y00, sigma_x, sigma_y, amplitude;

};

const unsigned Nx = 70, Ny = 40;
const double lx = 2., ly = 1.;
const double hx = lx/(double)Nx, hy = ly/(double)Ny;

int main()
{
    //Create Window and set window title
    draw::HostWindow w( 800, 400);
    // generate a vector on the grid to visualize 
    Gaussian g( 1.2, 0.3, .1, .1, 1);
    std::vector<float> visual(Nx*Ny);
    for(unsigned i=0; i<Ny; i++)
        for( unsigned j=0; j<Nx; j++)
            visual[i*Nx+j] = -g( (double)j*hx, (double)i*hy);

    //create a colormap
    draw::ColorMapRedBlueExt colors( 1.);
    //set scale
    colors.scale() =  1.;

    int running = GL_TRUE;
    while (running)
    {
        w.title() << "Hello world\n";
        w.draw( visual, Nx, Ny, colors);
        glfwWaitEvents();
        running = !glfwGetKey( GLFW_KEY_ESC) &&
                    glfwGetWindowParam( GLFW_OPENED);
    }

    return 0;
}
