#ifndef _HOST_WIDNOW_H_
#define _HOST_WIDNOW_H_

#include <cassert>

#include <algorithm>  //transform 
#include <vector>
#include <sstream>
//#include "../lib/timer.h"

#include "utility.h"
#include "colormap.h"

//maybe in future Qt is an alternative
namespace draw
{

///@addtogroup Rendering
///@{

/**
 * @brief Render object for 2d scientific plots 
 *
 * The intention of this class is to provide an interface to make 
 * the plot of a 2D vector during computations as simple as possible. 
 * To use it simply use something like
 * @code
 * #include "draw/host_window.h"
 *
 * int main()
 * {
 *     GLFWwindow* w = draw::glfwInitAndCreateWindow w( 400, 400, "Hello world!");
 *     RenderHostData render( 1,1);
       draw::ColorMapRedBlueExt map( 1.);
       std::vector<double> v( 100*100);
 *     while( !glfwWindowShouldClose(w))
 *     {
 *         //compute useful values for v
           render.renderQuad( v, 100, 100, map);
 *     }
 *     glfwTerminate();
 *     return 0;
 * }
 * @endcode
 * \note An OpenGl context has to be created before the render object. 
 */
struct RenderHostData
{
	/**
	 * @brief Init GL texturing and multiplot
	 *
	 * @param rows # of rows of quads in one scene
	 * @param cols # of columns of quads in the scene
	 */
    RenderHostData( int rows = 1, int cols = 1){

        Nx_ = Ny_ = 0;
        I = rows; J = cols;
        k = 0;
        //enable textures
        glEnable(GL_TEXTURE_2D);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glClearColor( 1.,1.,1.,0.);
        //window_str << "\n";
    }

    //Vector has to be useable in std functions
    /**
     * @brief Render a 2D field in the open window
     *
     * The first element of the given vector corresponds to the bottom left corner. (i.e. the 
     * origin of a 2D coordinate system) Successive
     * elements correspond to points from left to right and from bottom to top.
     * @note If multiplot is set the field will be drawn in the current active 
     * box. When all boxes are full the field will be drawn in the upper left box again. 
     * @tparam Vector The container class of your elements
     * @param x Elements to be drawn
     * @param Nx # of x points to be used ( the width)
     * @param Ny # of y points to be used ( the height)
     * @param map The colormap used to compute color from elements
     */
    template< class Vector>
    void renderQuad( const Vector& x, unsigned Nx, unsigned Ny, draw::ColorMapRedBlueExt& map)
    {
        if( Nx != Nx_ || Ny != Ny_) {
            Nx_ = Nx; Ny_ = Ny;
            std::cout << "Allocate resources for drawing!\n";
            resource.resize( Nx*Ny);
        }
        assert( x.size() >= resource.size());
        unsigned i = k/J, j = k%J;
        //map colors
        //toefl::Timer t;
        //t.tic();
        std::transform( x.begin(), x.begin()+Nx*Ny, resource.begin(), map);
        //t.toc();
        //std::cout << "Color mapping took "<<t.diff()*1000.<<"ms\n";
        //load texture
        float slit = 2./500.; //half distance between pictures in units of width
        float x0 = -1. + (float)2*j/(float)J, x1 = x0 + 2./(float)J, 
              y1 =  1. - (float)2*i/(float)I, y0 = y1 - 2./(float)I;
        //t.tic();
        drawTexture( Nx, Ny, x0 + slit, x1 - slit, y0 + slit, y1 - slit);
        if( k == (I*J-1) )
            k = 0;
        else
            k++;
        //t.toc();
        //std::cout << "Texture mapping took "<<t.diff()*1000.<<"ms\n";
    }
    /**
     * @brief Render an untextured Quad
     */
    void renderEmptyQuad()
    {
        unsigned i = k/J, j = k%J;
        float slit = 2./500.; //half distance between pictures in units of width
        float x0 = -1. + (float)2*j/(float)J, x1 = x0 + 2./(float)J, 
              y1 =  1. - (float)2*i/(float)I, y0 = y1 - 2./(float)I;
        //glLoadIdentity();
        glColor3f(1.,1.,1. );
        glBegin( GL_QUADS);
             glVertex2f( x0+slit, y0+slit);
             glVertex2f( x1-slit, y0+slit);
             glVertex2f( x1-slit, y1-slit);
             glVertex2f( x0+slit, y1-slit);
        glEnd();
        if( k == (I*J-1) )
            k = 0;
        else
            k++;

    }
    /**
     * @brief Set up multiple plots in one window_
     *
     * After this call, successive calls to the renderQuad function will draw 
     * into rectangular boxes from left to right and top to bottom.
     * @param i # of rows of boxes
     * @param j # of columns of boxes
     * @code 
     * w.set_multiplot( 1,2); //set up two boxes next to each other
     * w.renderQuad( first, 100 ,100, map); //draw in left box
     * w.renderQuad( second, 100 ,100, map); //draw in right box
     * @endcode
     */
    void set_multiplot( unsigned i, unsigned j) { I = i; J = j; k = 0;}

  private:
    unsigned I, J, k;
    void drawTexture( unsigned Nx, unsigned Ny, float x0, float x1, float y0, float y1)
    {
        // image comes from texarray on host
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, Nx, Ny, 0, GL_RGB, GL_FLOAT, resource.data());
        glLoadIdentity();
        glBegin(GL_QUADS);
            glTexCoord2f(0.0f, 0.0f); glVertex2f( x0, y0);
            glTexCoord2f(1.0f, 0.0f); glVertex2f( x1, y0);
            glTexCoord2f(1.0f, 1.0f); glVertex2f( x1, y1);
            glTexCoord2f(0.0f, 1.0f); glVertex2f( x0, y1);
        glEnd();
    }
    unsigned Nx_, Ny_;
    std::vector<Color> resource;
};
///@}
} //namespace draw

#endif//_HOST_WIDNOW_H_
