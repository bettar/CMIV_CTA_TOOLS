//
//  CMIVDCMView.m
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 12/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#define WITH_OPENGL_32 // core profile

#ifdef WITH_OPENGL_32
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"
#else
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLCurrent.h>
#import <OpenGL/CGLMacro.h>
#import <OpenGL/glu.h> // for gluUnProject, it includes gl.h
#endif

#import <MieleAPI/GLRenderer.h>

#import "CMIVDCMView.h"

// TODO: use vtkMath::RadiansFromDegrees() or glm::radians()
static float deg2rad = M_PI/180.0;

@implementation CMIVDCMView

- (id) windowController
{
    return dcmViewWindowController;
}

- (BOOL) is2DViewer
{
//	[super is2DViewer];
    return NO;
}

-(void)setDcmViewWindowController:(id)vc
{
    dcmViewWindowController=vc;
}

-(void)setTranlateSlider:(NSSlider*) aSlider
{
    tranlateSlider=aSlider;
}

-(void)setHorizontalSlider:(NSSlider*) aSlider
{
    horizontalSlider=aSlider;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    [super scrollWheel:theEvent];
    CGFloat x,y;
    float loc;
    float acceleratefactor=0.1;
    if (tranlateSlider!=nil)
    {
        if ([theEvent modifierFlags] & NSEventModifierFlagCommand)
            y=[theEvent deltaX];
        else
            y=[theEvent deltaY];

        if (y!=0)
        {
            if(y>0)
                y=(y-0.1)*acceleratefactor+0.1;
            else
                y=(y+0.1)*acceleratefactor-0.1;
            loc=[tranlateSlider floatValue];
            loc+=y*10;
            while(loc>[tranlateSlider maxValue])
                loc-=([tranlateSlider maxValue]-[tranlateSlider minValue]);
            while(loc<[tranlateSlider minValue])
                loc+=([tranlateSlider maxValue]-[tranlateSlider minValue]);
            [tranlateSlider setFloatValue:loc];
            [tranlateSlider performClick:self];
        }
    }

    if (horizontalSlider!=nil)
    {
        if ([theEvent modifierFlags] & NSEventModifierFlagCommand)
            x=[theEvent deltaY];
        else
            x=[theEvent deltaX];

        if (x!=0)
        {
            if(x>0)
                x=(x-0.1)*acceleratefactor+0.1;
            else
                x=(x+0.1)*acceleratefactor-0.1;
            loc=[horizontalSlider floatValue];
            loc-=x*10;
            while(loc>[horizontalSlider maxValue])
                loc-=([horizontalSlider maxValue]-[horizontalSlider minValue]);
            while(loc<[horizontalSlider minValue])
                loc+=([horizontalSlider maxValue]-[horizontalSlider minValue]);
            
            [horizontalSlider setFloatValue:loc];
            [horizontalSlider performClick:self];
        }
        
    }

    if (tranlateSlider==nil&&horizontalSlider==nil)
        [[self nextResponder] scrollWheel:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[NSNotificationCenter defaultCenter] postNotificationName: @"cmivCTAViewMouseDown" object:self userInfo: [NSDictionary dictionaryWithObject:@"mouseDown" forKey:@"action"]];
    
    if (displayCrossLines &&
       [theEvent type] == NSLeftMouseDown)
    {
        NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint:[theEvent locationInWindow] fromView:nil]];
        int mouseOnLines=[self checkMouseOnCrossLines:mouseLocation];
        if ( mouseOnLines==2)
        {
            ifLeftButtonDown=1;
            mouseOperation=2;
            [NSCursor hide];
            
        }
        else if ( mouseOnLines==1)
        {
            ifLeftButtonDown=1;
            mouseOperation=1;
            mouseToCrossXAngle=[self angleToCrossXFromPt:mouseLocation];
        }
        else
        {
            mouseOperation=0;
            [super mouseDown:theEvent];
        }
    }
    else
        [super mouseDown:theEvent];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    if (displayCrossLines && mouseOperation==2)
    {
        NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint:[theEvent locationInWindow] fromView:nil]];
        crossPoint=mouseLocation;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:self userInfo: [NSDictionary dictionaryWithObject:@"dragged" forKey:@"action"]];
        [super mouseMoved:theEvent];
        [self setNeedsDisplay: YES];
    }
    else if (displayCrossLines && mouseOperation==1)
    {
        NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint:[theEvent locationInWindow] fromView:nil]];
        float newangletocrossx=[self angleToCrossXFromPt:mouseLocation];
        crossAngle=newangletocrossx-mouseToCrossXAngle;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:self userInfo: [NSDictionary dictionaryWithObject:@"dragged" forKey:@"action"]];
        [self setNeedsDisplay:YES];
    }
    else
    {
        [super mouseDragged:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [[NSNotificationCenter defaultCenter] postNotificationName: @"cmivCTAViewMouseUp" object:self userInfo: [NSDictionary dictionaryWithObject:@"mouseUp" forKey:@"action"]];
    ifLeftButtonDown=0;
    if (displayCrossLines && mouseOperation)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:self userInfo: [NSDictionary dictionaryWithObject:@"mouseUp" forKey:@"action"]];
        mouseOperation=0;
        [NSCursor unhide];
        [self checkCursor];
        [self setNeedsDisplay:YES];
        
    }
    else
    {
        [super mouseUp:theEvent];
    }
}

- (void) mouseMoved: (NSEvent *) theEvent
{
    [super mouseMoved: theEvent];
    if(displayCrossLines)
    {
        NSView* view = [[[theEvent window] contentView] hitTest:[theEvent locationInWindow]];
        if( view == self)
        {
            
            NSPoint mouseLocation = [self ConvertFromNSView2GL: [self convertPoint:[theEvent locationInWindow] fromView:nil]];
            int mouseOnLines=[self checkMouseOnCrossLines:mouseLocation];
            if( mouseOnLines==2)
            {
                if( [theEvent type] == NSLeftMouseDragged)
                    [[NSCursor closedHandCursor] set];
                else
                    [[NSCursor openHandCursor] set];
            }
            else if( mouseOnLines==1)
            {
                [[NSCursor rotateAxisCursor] set];
            }
            else
            {
                //[cursor set];
                [self checkCursor];
            }
            
        }
    }
}

-(int) checkMouseOnCrossLines:(NSPoint)mouseLocation
{
    int mouseOnLines=0;
    float centerheight = self.frame.size.height*0.1;
    float centerwidth = self.frame.size.width*0.1;
    float mousetocenterx=(mouseLocation.x-crossPoint.x)*[self scaleValue];
    float mousetocentery=(mouseLocation.y-crossPoint.y)*[self scaleValue];
    //abs(mousetocenterx)
    if(mousetocenterx<0)
        mousetocenterx=-mousetocenterx;
    if(mousetocentery<0)
        mousetocentery=-mousetocentery;
    
    // In center move
    if(mousetocenterx<centerwidth&&mousetocentery<centerheight)
    {
        if(mousetocenterx<10&&mousetocentery<10)
            mouseOnLines=2;
    }
    else if(mousetocenterx<10.0)
        mouseOnLines=1;
    else if(mousetocentery<10.0)
        mouseOnLines=1;
    else
        mouseOnLines=0;

    return mouseOnLines;
}

-(float) angleToCrossXFromPt:(NSPoint)pt
{
    float x,y,angle;
    x=pt.x-crossPoint.x;
    y=pt.y-crossPoint.y;
    if ((int)(x*10000)==0)
        angle=90;
    else
    {
        angle=atan(y/x) / deg2rad;
    }
    if (x<0)
        angle+=180;

    return angle;
}

- (void)keyDown:(NSEvent *)event
{
    unsigned short i=[event keyCode];
    if((i>=123 && i<=126)||i==121||i==116)//arrows and pageup&down
    {
        float x=0,y=0;
        float loc;
        float acceleratefactor=1.0;
        if(tranlateSlider!=nil)
        {
            if ([event modifierFlags] & NSEventModifierFlagOption)
                acceleratefactor=10.0;
            
            if( i==121)
                y=1;
            else if(i==116)
                y=-1;

            if(y!=0)
            {
                loc=[tranlateSlider floatValue];
                loc+=y*acceleratefactor;
                while(loc>[tranlateSlider maxValue])
                    loc-=([tranlateSlider maxValue]-[tranlateSlider minValue]);
                while(loc<[tranlateSlider minValue])
                    loc+=([tranlateSlider maxValue]-[tranlateSlider minValue]);
                [tranlateSlider setFloatValue:loc];
                [tranlateSlider performClick:self];
            }
        }

        if(horizontalSlider!=nil)
        {
            if(i==124)
            {
                x=1;
            }
            else if(i==123)
            {
                x=-1;
            }

            if(x!=0)
            {
                loc=[horizontalSlider floatValue];
                loc+=x*acceleratefactor;
                while(loc>[horizontalSlider maxValue])
                    loc-=([horizontalSlider maxValue]-[horizontalSlider minValue]);
                while(loc<[horizontalSlider minValue])
                    loc+=([horizontalSlider maxValue]-[horizontalSlider minValue]);
                
                [horizontalSlider setFloatValue:loc];
                [horizontalSlider performClick:self];
            }
        }

        if(tranlateSlider==nil&&horizontalSlider==nil)
            [[self nextResponder] keyDown:event];
    }
    else
        [super keyDown:event];
}

- (void) setMPRAngle: (float) vectorMPR
{
    crossAngle=vectorMPR;
}

- (float) angle
{
    return crossAngle;
}

- (void) setCrossCoordinates:(float) x :(float) y :(BOOL) update
{
    crossPoint.x=x;
    crossPoint.y=-y; // to compatible with previous version, here we mimic the old version function
    [self setNeedsDisplay: YES];
}

- (void) getCrossCoordinates:(float*) x :(float*) y
{
    *x=crossPoint.x;
    *y=-crossPoint.y;// to compatible with previous version, here we mimic the old version function
}

- (void) subDrawRect: (NSRect) r
{
    [self setScaleValue:2.3]; // @@@ FIXME: otherwise the zoom level is 10000%
    
    if (displayCrossLines)
    {
        renderer_enable_blend_smooth();

        float heighthalf = self.frame.size.height/2;
        float widthhalf = self.frame.size.width/2;
        
        float lineWidth;
        float pointSize;
        float backingScaleFactor = self.window.backingScaleFactor;
        
        if (widthhalf > 800)
            lineWidth = pointSize = 4.0;
        else
            lineWidth = pointSize = 2.0;

#ifndef WITH_OPENGL_32
        glLineWidth(lineWidth * backingScaleFactor);
#endif
        
        float crossglX=0.;
        float crossglY=0.;
        if (curDCM)
        {
            crossglX = [self scaleValue] * (crossPoint.x-curDCM.pwidth/2.);
            crossglY = [self scaleValue] * (crossPoint.y-curDCM.pheight/2.);
        }
        
#ifdef WITH_OPENGL_32
        glm::mat4 MV = glm::mat4(1.0);
        MV = glm::translate(MV, glm::vec3(crossglX, crossglY, 0.0f));
        MV = glm::rotate(MV, glm::radians(crossAngle), glm::vec3(0,0,1));
#else // @@@ OGL
        glTranslatef(crossglX, crossglY, 0.0);
        glRotatef( crossAngle, 0, 0, 1);
#endif

        // Drawing x axis
        {
            glm::vec2 pA[10];
            int nPoints=0;
            
            pA[ nPoints++] = glm::vec2( -widthhalf*2,   0);
            pA[ nPoints++] = glm::vec2( -widthhalf*0.2, 0);
            pA[ nPoints++] = glm::vec2( +widthhalf*2,   0);
            pA[ nPoints++] = glm::vec2( +widthhalf*0.2, 0);
            
            NSMutableArray *pArray = [NSMutableArray array];
            for (int i=0; i<nPoints; i++)
            {
#ifdef WITH_OPENGL_32
                // Apply local model transformation
                glm::vec4 pB = MV*glm::vec4(pA[i],0,1);
                pA[i] = glm::vec2(pB.x, pB.y);
#endif
                [pArray addObject: [NSValue valueWithBytes:&pA[i] objCType:@encode(glm::vec2)]];
            }
         
            [self setShaderProgramForLineWidth: lineWidth * backingScaleFactor];
            renderer_set_rgba(0.0, 0.0, 1.0, 0.5);
            renderer_drawLine_xy([pArray copy], GL_LINES);
        }
        
        // Drawing y axis
        {
            glm::vec2 pA[10];
            int nPoints=0;
            
            pA[ nPoints++] = glm::vec2(  0, -heighthalf*2);
            pA[ nPoints++] = glm::vec2(  0, -heighthalf*0.2);
            pA[ nPoints++] = glm::vec2(  0, +heighthalf*2);
            pA[ nPoints++] = glm::vec2(  0, +heighthalf*0.2);
            
            NSMutableArray *pArray = [NSMutableArray array];
            for (int i=0; i<nPoints; i++)
            {
#ifdef WITH_OPENGL_32
                // Apply local model transformation
                glm::vec4 pB = MV*glm::vec4(pA[i],0,1);
                pA[i] = glm::vec2(pB.x, pB.y);
#endif
                [pArray addObject: [NSValue valueWithBytes:&pA[i] objCType:@encode(glm::vec2)]];
            }
            
            [self setShaderProgramForLineWidth: lineWidth * backingScaleFactor];
            renderer_set_rgba(1.0, 0.0, 0.0, 0.5);
            renderer_drawLine_xy([pArray copy], GL_LINES);
        }
        
        // Drawing the center point
        {
            glm::vec2 a(0, 0);
#ifdef WITH_OPENGL_32
            // Apply local model transformation
            glm::vec4 pB = MV*glm::vec4(a,0,1);
            a = glm::vec2(pB.x, pB.y);
#endif
            NSMutableArray *pArray = [NSMutableArray array];
            [pArray addObject: [NSValue valueWithBytes:&a objCType:@encode(glm::vec2)]];
           
            [self setShaderProgramOverlay_withMode_Point];

            if (ifLeftButtonDown)
                renderer_set_rgba(0.0, 1.0, 0.0, 1.0);
            else
                renderer_set_rgba(0.0, 1.0, 0.0, 0.5);
            
            renderer_set_point_size( pointSize * backingScaleFactor);
            renderer_drawPoints([pArray copy]);
        }
        
        renderer_disable_blend_smooth();

        // FIXME: do this in host app
        [self setShaderProgramForLineWidth: lineWidth * backingScaleFactor];
                
#ifndef WITH_OPENGL_32
        glLineWidth(2.0);
        renderer_set_point_size(2.0);

        glRotatef( -crossAngle, 0, 0, 1);
        glTranslatef(-crossglX, -crossglY, 0.0);
#endif
    }
}

-(void)showCrossHair
{
    displayCrossLines=TRUE;
}

-(void)hideCrossHair;
{
    displayCrossLines=FALSE;
}

@end
