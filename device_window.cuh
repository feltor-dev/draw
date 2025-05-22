#ifndef _DEVICE_WINDOW_CUH_
#define _DEVICE_WINDOW_CUH_

#include <sstream>
#include <cassert>
#include <GL/glew.h>
#include <cuda_gl_interop.h>

#include <thrust/version.h>
#include <thrust/device_vector.h>
#include <thrust/transform.h>
#include <thrust/execution_policy.h>

#include "colormap.cuh"
#include "utility.h"

namespace draw
{
///@addtogroup Rendering
///@{

/**
 * @brief Render Object that uses data from your CUDA computations

 * The aim of this class is to provide an interface to make
 * the plot of a 2D vector during CUDA computations as simple as possible.
 * Uses the cuda_gl_interop functionality
 * @code
 * #include <thrust/device_vector.h>
 * #include "draw/device_window.h"
 *
 * int main()
 * {
 *     GLFWwindow* w = draw::glfwInitAndCreateWindow w( 400, 400, "Hello world!");
 *     RenderDeviceData render( 1,1);
       draw::ColorMapRedBlueExt map( 1.);
       thrust::device_vector<double> v( 100*100);
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
struct RenderDeviceData
{
	/**
	 * @brief Init Cuda - OpenGL texturing and multiplot
	 *
	 * @param rows # of rows of quads in one scene
	 * @param cols # of columns of quads in the scene
	 */
    RenderDeviceData( int rows = 1, int cols = 1) {
        resource_ = 0;
        Nx_ = Ny_ = 0;
        I = rows; J = cols;
        k = 0;
        cudaGlInit( );
        //glClearColor( 0.f, 0.f, 1.f, 0.f);
        glClear(GL_COLOR_BUFFER_BIT);
        m_resource_registered = m_buffer_allocated = false;
    }
    /**
     * @brief free resources
     */
    ~RenderDeviceData( ) {
        if( m_resource_registered)
            cudaGraphicsUnregisterResource( resource_);
        //free the opengl buffer
        if( m_buffer_allocated)
        {
            GLint id;
            glGetIntegerv( GL_PIXEL_UNPACK_BUFFER_BINDING, &id);
            GLuint bufferID = (GLuint)id;
            glDeleteBuffers( 1, &bufferID);
        }
    }
    /**
     * @brief Set up multiple plots in one window
     *
     * After this call, successive calls to the renderQuad function will draw
     * into rectangular boxes from left to right and top to bottom.
     * @param i # of rows of boxes
     * @param j # of columns of boxes
     * @code
     * w.set_multiplot( 1,2); //set up two boxes next to each other
     * w.draw( first, 100 ,100, map); //draw in left box
     * w.draw( second, 100 ,100, map); //draw in right box
     * @endcode
     */
    void set_multiplot( unsigned i, unsigned j) { I = i; J = j; k = 0;}
    /**
     * @brief Draw a 2D field in the open window
     *
     * The first element of the given vector corresponds to the bottom left corner. (i.e. the
     * origin of a 2D coordinate system) Successive
     * elements correspond to points from left to right and from bottom to top.
     * @note If multiplot is set the field will be drawn in the current active
     * box. When all boxes are full the field will be drawn in the upper left box again.
     * @tparam T The datatype of your elements
     * @param x Elements to be drawn lying on the device
     * @param Nx # of x points to be used ( the width)
     * @param Ny # of y points to be used ( the height)
     * @param map The colormap used to compute color from elements
     */
    template< class T>
    void renderQuad( const thrust::device_vector<T>& x, unsigned Nx, unsigned Ny, draw::ColorMapRedBlueExt& map)
    {
        if( Nx != Nx_ || Ny != Ny_) {
            Nx_ = Nx; Ny_ = Ny;
            if( m_resource_registered)
            {
                cudaError_t error;
                error = cudaGraphicsUnregisterResource( resource_);
                if( error != cudaSuccess){
                    std::cerr << cudaGetErrorString( error); }
                m_resource_registered = false;
            }
            std::cout << "Allocate resources for drawing!\n";
            //free opengl buffer
            GLint id;
            if( m_buffer_allocated)
            {
                glGetIntegerv( GL_PIXEL_UNPACK_BUFFER_BINDING, &id);
                GLuint bufferID = (GLuint)id;
                glDeleteBuffers( 1, &bufferID);
                m_buffer_allocated = false;
            }
            //allocate new buffer and register
            allocateCudaGlBuffer( 3*Nx*Ny);
        }
        //map colors
        mapColors( map, x);

        unsigned i = k/J, j = k%J;
        float slit = 2./500.; //half distance between pictures in units of width
        float x0 = -1. + (float)2*j/(float)J, x1 = x0 + 2./(float)J,
              y1 =  1. - (float)2*i/(float)I, y0 = y1 - 2./(float)I;
        drawTexture( Nx, Ny, x0 + slit, x1 - slit, y0 + slit, y1 - slit);
        if( k == (I*J-1) )
            k = 0;
        else
            k++;
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
        glLoadIdentity();
        glBegin(GL_QUADS);
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

  private:
    RenderDeviceData( const RenderDeviceData&);
    RenderDeviceData& operator=( const RenderDeviceData&);
    unsigned I, J, k;
    cudaGraphicsResource* resource_;
    bool m_resource_registered, m_buffer_allocated;
    unsigned Nx_, Ny_;
    void drawTexture( unsigned Nx, unsigned Ny, float x0, float x1, float y0, float y1)
    {
        // image comes from device resource
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, Nx, Ny, 0, GL_RGB, GL_FLOAT, NULL);
        glLoadIdentity();
        glBegin(GL_QUADS);
            glTexCoord2f(0.0f, 0.0f); glVertex2f( x0, y0);
            glTexCoord2f(1.0f, 0.0f); glVertex2f( x1, y0);
            glTexCoord2f(1.0f, 1.0f); glVertex2f( x1, y1);
            glTexCoord2f(0.0f, 1.0f); glVertex2f( x0, y1);
        glEnd();
    }
    template< class T>
    void mapColors( const draw::ColorMapRedBlueExt& map, const thrust::device_vector<T>& x)
    {
        draw::Color* d_buffer;
        size_t size;
        //Map resource into CUDA memory space
        cudaError_t error;
        error = cudaGraphicsMapResources( 1, &resource_, 0);
        if( error != cudaSuccess){
            std::cerr << cudaGetErrorString( error); }
        // get a pointer to the mapped resource
        error = cudaGraphicsResourceGetMappedPointer( (void**)&d_buffer, &size, resource_);
        if( error != cudaSuccess){
            std::cerr << cudaGetErrorString( error); }
        assert( x.size() == size/3/sizeof(float));
        thrust::transform( x.begin(), x.end(), thrust::device_pointer_cast<draw::Color>( d_buffer), map);
        //unmap the resource before OpenGL uses it
        error = cudaGraphicsUnmapResources( 1, &resource_, 0);
        if( error != cudaSuccess){
            std::cerr << cudaGetErrorString( error); }
    }
    void cudaGlInit( )
    {
        //initialize glew (needed for GLbuffer allocation)
        GLenum err = glewInit();
        if (GLEW_OK != err)
        {
              /* Problem: glewInit failed, something is seriously wrong. */
            std::cerr << "Error: " << glewGetErrorString(err) << "\n";
            return;
        }
        //std::cout << "Using GLEW version   " << glewGetString(GLEW_VERSION) <<"\n";

        //int device;
        //cudaGetDevice( &device);
        //std::cout << "Using device number  "<<device<<"\n";
        //cudaGLSetGLDevice( device );
        //std::cout << "Using THRUST version "<<THRUST_MAJOR_VERSION<<"."<<THRUST_MINOR_VERSION<<"."<<THRUST_SUBMINOR_VERSION<<"\n";
        //std::cout << "(thrust version should be 1.7.0)\n";

        //cudaError_t error;
        //error = cudaGetLastError();
        //if( error != cudaSuccess){
        //    std::cout << cudaGetErrorString( error);}
        glEnable(GL_TEXTURE_2D);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }

    GLuint allocateGlBuffer( unsigned N)
    {
        GLuint bufferID;
        glGenBuffers( 1, &bufferID);
        glBindBuffer( GL_PIXEL_UNPACK_BUFFER, bufferID);
        // the buffer shall contain a texture
        glBufferData( GL_PIXEL_UNPACK_BUFFER, N*sizeof(float), NULL, GL_DYNAMIC_DRAW);
        return bufferID;
    }

    //N should be 3*Nx*Ny
    void allocateCudaGlBuffer( unsigned N )
    {
        int device;
        cudaGetDevice( &device);
        std::cout << "Using device number  "<<device<<"\n";
        GLuint bufferID = allocateGlBuffer( N);
        m_buffer_allocated = true;
        //register the resource i.e. tell CUDA and OpenGL that buffer is used by both
        cudaError_t error;
        error = cudaGraphicsGLRegisterBuffer( &resource_, bufferID, cudaGraphicsRegisterFlagsWriteDiscard);
        if( error != cudaSuccess){
            std::cout << cudaGetErrorString( error); }
        m_resource_registered = true;
    }
};
///@}

} //namespace draw

#endif//_DEVICE_WINDOW_CUH_
