//
//  OpenGLView.swift
//  OpenGLESTutorial
//
//  Created by zhongzhendong on 4/27/16.
//  Copyright © 2016 zhongzhendong. All rights reserved.
//

import UIKit

class OpenGLView03: UIView {
    private var eaglLayer = CAEAGLLayer()
    private var context = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    private var colorRenderBuffer: GLuint = 0
    private var frameBuffer: GLuint = 0
    
    private var programHandle: GLuint = 0
    private var positionSlot: Int32 = 0
    private var projectionSlot: Int32 = 0
    private var modelViewSlot: Int32 = 0
    
    private var modelViewMatrix = ksMatrix4()
    private var projectionMatrix = ksMatrix4()
    
    private var posX: Float = 0
    
    private var posY: Float = 0
    
    private var posZ: Float = 0
    
    private var rotateX: Float = 0
    private var rotateY: Float = 0
    
    private var scaleZ: Float = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:)))
        self.addGestureRecognizer(gesture)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapGenstreHandler(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        setupLayer()
        setupContext()
        setupProgram()
        setupProjection()
        
        resetTransform()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private var lastPoint = CGPointZero
    
    func panGestureHandler(gesture: UIPanGestureRecognizer) {
        let velocity = gesture.velocityInView(self)
        let point = gesture.locationInView(self)
        
        switch gesture.state {
        case .Began:
            lastPoint = point
        case .Changed:
            if fabs(velocity.x) > fabs(velocity.y) {
                print("x轴运动：\(point.y)")
                
                rotateY += Float((point.x - lastPoint.x) / frame.height * 180)
                lastPoint = point
                updateTransform()
                render()
                
            }else {
                print("y轴运动：\(point.y)")
                
                rotateX += Float((point.y - lastPoint.y) / frame.height * 180)
                lastPoint = point
                updateTransform()
                render()
            }
        default:
            break
        }
    }
    
    func doubleTapGenstreHandler(gesture: UITapGestureRecognizer) {
        resetTransform()
    }
    
    
    override class func layerClass() -> AnyClass{
        return CAEAGLLayer.self
    }
    
    override func layoutSubviews() {
        
        destoryRenderAndFrameBuffer()
        
        setupRenderBuffer()
        setupFrameBuffer()
        
        updateTransform()
        
        render()
    }
    
    private func resetTransform() {
        posX = 0.0
        posY = 0.0
        posZ = -5.5
        
        scaleZ = 1.0
        rotateX = 0.0
        
        updateTransform()
    }
    
    private func render() {
        glClearColor(0, 1.0, 0, 1.0)
        glClear(UInt32(GL_COLOR_BUFFER_BIT))
        
        //setup viewport
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        let vertices:[GLfloat] = [0.5, 0.5, 0.0,
                                  0.5, -0.5, 0.0,
                                  -0.5, -0.5, 0.0,
                                  -0.5, 0.5, 0.0,
                                  0.0, 0.0 ,-0.707]
        
        let indices:[GLubyte] = [0, 1,
                                 1, 2,
                                 2, 3,
                                 3, 0,
                                 4, 0,
                                 4, 1,
                                 4, 2,
                                 4, 3]
        
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices)
        glEnableVertexAttribArray(0)
        
        glDrawElements(GLenum(GL_LINES), GLsizei(indices.count), GLenum(GL_UNSIGNED_BYTE), indices)
        
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
        
        positionSlot = glGetAttribLocation(GLuint(programHandle), "vPostion")
        modelViewSlot = glGetUniformLocation(GLuint(programHandle), "modelView")
        projectionSlot = glGetUniformLocation(GLuint(programHandle), "projection")
    }
    
    private func setupProjection() {
        let aspect = Float(frame.width / frame.height)
        
        ksMatrixLoadIdentity(&projectionMatrix)
        ksPerspective(&projectionMatrix, 60.0, aspect, 1.0, 20.0)
        
        glUniformMatrix4fv(projectionSlot, 1, GLboolean(GL_FALSE), &projectionMatrix.m.0.0)
    }

    private func updateTransform() {
        ksMatrixLoadIdentity(&modelViewMatrix);
        
        // Translate away from the viewer
        ksMatrixTranslate(&modelViewMatrix, self.posX, self.posY, self.posZ);
        
        // Rotate the triangle
        ksMatrixRotate(&modelViewMatrix, self.rotateX, 1.0, 0.0, 0.0);
        ksMatrixRotate(&modelViewMatrix, self.rotateY, 0.0, 1.0, 0.0);
        
        // Scale the triangle
        ksMatrixScale(&modelViewMatrix, 1.0, 1.0, self.scaleZ);
        
        glUniformMatrix4fv(modelViewSlot, 1, GLboolean(GL_FALSE), &modelViewMatrix.m.0.0)
    }
}
