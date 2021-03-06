//
//  FAViewController.m
//  FaceArt
//
//  Created by Mark Strand on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FAViewController.h"
#import "shaders.h"
#import "bufferData.h"

@implementation FAViewController


@synthesize context;
@synthesize _effect;
@synthesize vertices;
@synthesize texture;





- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self._effect = [[GLKBaseEffect alloc] init];
    
    vertices = [[NSMutableArray alloc]initWithCapacity:200];
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ellipseVertices), textureVertices, GL_STATIC_DRAW);
    
//    glGenBuffers(1, &_indexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(ellipseIndices), ellipseIndices, GL_STATIC_DRAW);
    
    _aspect = 40.0;
    
    // load texture data
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"rocks" ofType:@"JPG"];
    NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
    UIImage *image = [[UIImage alloc] initWithData:texData];
    if(image == nil)
        NSLog(@"couldn't open image");
    
    texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
    
    if(error)
        NSLog(@"couldn't load texture from image %@",error);
    
    if (texture != nil) {
        self._effect.texture2d0.envMode = GLKTextureEnvModeReplace;
        self._effect.texture2d0.target = GLKTextureTarget2D;
        self._effect.texture2d0.name = texture.name;
    }
    
    GLuint width = CGImageGetWidth(image.CGImage);
    GLuint height = CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(height * width * 4);
    CGContextRef ccontext = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextClearRect(ccontext, CGRectMake(0,0,width, height));
    CGContextTranslateCTM(ccontext, 0, height - height);
    CGContextDrawImage(ccontext, CGRectMake(0, 0, width, height), image.CGImage);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    
    NSLog([NSString stringWithFormat:@"%s",shaders[1]]);
    
    GLuint vsh;
    
    vsh = [self createShader:GL_VERTEX_SHADER source:shaders[0]];
    
}

-(void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    self._effect = nil;
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.preferredFramesPerSecond = 30;
    
    
    if (!self.context) {
        NSLog(@"failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    [self setupGL];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) 
    {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    _touchX  += 1;
//    _touchY  += 1;
   
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:[touch view]];
   _touchX = touchLocation.x;
    _touchY = touchLocation.y;
    
    _touchY = 0.0;
    _touchY = 0.0;
    
    [self.view setNeedsDisplay];
}

#pragma mark GLKViewDelegate

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [self._effect prepareToDraw];
    

    
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex,Position));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
   // glDrawElements(GL_TRIANGLE_STRIP, sizeof(ellipseIndices) /sizeof(ellipseIndices[0]), GL_UNSIGNED_BYTE, 0);
    glDrawElements(GL_TRIANGLE_STRIP, 2, GL_UNSIGNED_BYTE, 0);
}

#pragma mark GLKViewControllerDelegate

-(void)update
{
    if (_increasing) 
    {
        _curRed += 1.0 * self.timeSinceLastUpdate;
        _aspect += 2;
    }
    else 
    {
        _curRed -= 1.0 * self.timeSinceLastUpdate;
        _aspect -= 2;
    }
    
    if (_curRed >= 1.0) 
    {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) 
    {
        _curRed = 0.0;
        _increasing = YES;
    }
   
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    //GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(_aspect), aspect, 4.0, 10.0);
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-5, 3, -4, 2, 4.0, 10.0);
    self._effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0 , 0.0, -6.0);
    
    _rotation += 90 * self.timeSinceLastUpdate;
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 0, 1);
    self._effect.transform.modelviewMatrix = modelViewMatrix;
}

#pragma mark shader stuff

-(GLuint)createShader:(GLenum)type source:(const char*)source
{
    GLuint name;
    
    name = glCreateShader(type);
    
    glShaderSource(name, 1, &source, NULL);
    
    glCompileShader(name);
    
    return name;
}

@end
