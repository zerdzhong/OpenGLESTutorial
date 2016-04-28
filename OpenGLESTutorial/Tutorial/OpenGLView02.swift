//
//  OpenGLView.swift
//  OpenGLESTutorial
//
//  Created by zhongzhendong on 4/27/16.
//  Copyright © 2016 zhongzhendong. All rights reserved.
//

import UIKit

class OpenGLView02: UIView {
    private var eaglLayer = CAEAGLLayer()
    private var context = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    private var colorRenderBuffer: GLuint = 0
    private var frameBuffer: GLuint = 0
    
    private var programHandle: GLuint = 0
//    private var positionSlot: Int32 = 0
    
    override class func layerClass() -> AnyClass{
        return CAEAGLLayer.self
    }
    
    override func layoutSubviews() {
        setupLayer()
        setupContext()
        
        destoryRenderAndFrameBuffer()
        setupRenderBuffer()
        setupFrameBuffer()
        setupProgram()
        
        render()
    }
    
    private func render() {
        glClearColor(0, 1.0, 0, 1.0)
        glClear(UInt32(GL_COLOR_BUFFER_BIT))
        
        //setup viewport
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        let vertices:[GLfloat] = [0.0, 0.5, 0.0,
                                  -0.5,-0.5,0.0,
                                  0.5, -0.5,0.0]
        
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices)
        glEnableVertexAttribArray(0)
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        
        
        context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    
    private func setupLayer() {
        eaglLayer = self.layer as! CAEAGLLayer
        eaglLayer.opaque = true
        eaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : NSNumber(bool: false),
                                        kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8]
    }
    
    private func setupContext() {
        if context == nil  {
            print("Failed to initialize OpenGLES 2.0 context")
        }
        
        if !EAGLContext.setCurrentContext(context) {
            print("Failed to set current OpenGL context")
        }
    }
    
    private func setupRenderBuffer() {
        glGenRenderbuffers(1, &colorRenderBuffer)
        glBindRenderbuffer(UInt32(GL_RENDERBUFFER), colorRenderBuffer)
        //分配存储空间
        context.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: eaglLayer)
    }
    
    private func setupFrameBuffer() {
        
        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(UInt32(GL_FRAMEBUFFER), frameBuffer)
        
        // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(UInt32(GL_FRAMEBUFFER),
                                  UInt32(GL_COLOR_ATTACHMENT0),
                                  UInt32(GL_RENDERBUFFER),
                                  colorRenderBuffer)
    }
    
    private func destoryRenderAndFrameBuffer() {
        glDeleteFramebuffers(1, &frameBuffer)
        frameBuffer = 0
        
        glDeleteRenderbuffers(1, &colorRenderBuffer)
        colorRenderBuffer = 0
    }
    
    private func setupProgram() {
        
        let vertexShader = loadShader(UInt32(GL_VERTEX_SHADER),
                                      shaderPath: NSBundle.mainBundle().pathForResource("VertexShader", ofType: "glsl")!)

        let fragmentShader = loadShader(UInt32(GL_FRAGMENT_SHADER),
                                        shaderPath: NSBundle.mainBundle().pathForResource("FragmentShader", ofType: "glsl")!)

        //创建编程管道，装载着色器
        
        programHandle = glCreateProgram()
        if programHandle == 0 {
            print("Failed to create program")
            return
        }
        
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        
        glLinkProgram(programHandle)
        
        var status: GLint = 0
        glGetProgramiv(programHandle, UInt32(GL_LINK_STATUS), &status)
        
        if status == GL_FALSE {
            var logLength:GLint = 0
            glGetProgramiv(programHandle, UInt32(GL_INFO_LOG_LENGTH), &logLength);
            
            if logLength > 0 {
                let log = malloc(Int(logLength))
                glGetProgramInfoLog(programHandle, logLength, &logLength, unsafeBitCast(log, UnsafeMutablePointer<GLchar>.self));
                print("Program validate log:\(log)")
                free(log);
            }

            glDeleteProgram(programHandle)
            programHandle = 0
            
            return
        }
        
        glUseProgram(programHandle)
        
//        positionSlot = glGetAttribLocation(GLuint(programHandle), "vPostion")
    }

}
