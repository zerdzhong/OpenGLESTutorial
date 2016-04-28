//
//  OpenGLView.swift
//  OpenGLESTutorial
//
//  Created by zhongzhendong on 4/27/16.
//  Copyright © 2016 zhongzhendong. All rights reserved.
//

import UIKit

class OpenGLView01: UIView {
    private var eaglLayer = CAEAGLLayer()
    private var context = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    private var colorRenderBuffer: GLuint = 0
    private var frameBuffer: GLuint = 0
    
    override class func layerClass() -> AnyClass{
        return CAEAGLLayer.self
    }
    
    func render() {
        glClearColor(0, 1.0, 0, 1.0)
        glClear(UInt32(GL_COLOR_BUFFER_BIT))
        
        context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    override func layoutSubviews() {
        setupLayer()
        setupContext()
        
        destoryRenderAndFrameBuffer()
        setupRenderBuffer()
        setupFrameBuffer()
        
        render()
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

}
