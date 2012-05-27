//
//  ScreenLayer.m
//  SNES4iPad
//
//  Created by Yusef Napora on 5/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ScreenLayer.h"
#import "SettingsViewController.h"
#import <math.h>

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)
#define DEGREES(radians) (radians * 180.0/M_PI)

unsigned int *screenPixels;

@implementation ScreenLayer

@synthesize rotateTransform;

+ (id) defaultActionForKey:(NSString *)key
{
    return nil;
}

- (id)init {
	if (self = [super init])
	{
		NSLog(@"creating IOSurface buffer");
		CFMutableDictionaryRef dict;
		int w = 256; 
		int h = 224; 
		int pitch = w * 2, allocSize = 2 * w * h;
        int bytesPerElement = 2;
	    char pixelFormat[4] = {'5', '6', '5', 'L'};
		
		dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
										 &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(dict, kIOSurfaceIsGlobal, kCFBooleanTrue);
        
        CFNumberRef num1 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch);
		CFDictionarySetValue(dict, kIOSurfaceBytesPerRow, num1);
        CFRelease(num1);
        
        CFNumberRef num2 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bytesPerElement);
		CFDictionarySetValue(dict, kIOSurfaceBytesPerElement, num2);
        CFRelease(num2);
        
        CFNumberRef num3 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &w);
		CFDictionarySetValue(dict, kIOSurfaceWidth, num3);
        CFRelease(num3);
        
        CFNumberRef num4 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &h);
		CFDictionarySetValue(dict, kIOSurfaceHeight, num4);
        CFRelease(num4);
        
        CFNumberRef num5 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat);
		CFDictionarySetValue(dict, kIOSurfacePixelFormat, num5);
        CFRelease(num5);
        
        CFNumberRef num6 = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &allocSize);
		CFDictionarySetValue(dict, kIOSurfaceAllocSize, num6);
		CFRelease(num6);
        
		_surface = IOSurfaceCreate(dict);
        
        CFRelease(dict);
        
        NSLog(@"created IOSurface at %p", _surface);

		screenPixels = IOSurfaceGetBaseAddress(_surface);
        NSLog(@"Base address: %p", screenPixels);
		
        rotateTransform = CGAffineTransformMakeRotation(RADIANS(90));
        self.affineTransform = rotateTransform;
		if ([SettingsController().smoothScaling isOn])
		{
			[self setMagnificationFilter: kCAFilterLinear];
		} else {
			[self setMagnificationFilter: kCAFilterNearest];
		}
		
		/*if (1) {
		    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(orientationChanged:) 
                                                         name:@"UIDeviceOrientationDidChangeNotification" 
                                                       object:nil];
        }*/
	}
	return self;
}
		

- (void)display {
    //NSLog(@"ScreenLayer display");
    IOSurfaceLock(_surface, 1, &_seed);
    self.affineTransform = CGAffineTransformIdentity;
    self.contents = nil;
    self.affineTransform = rotateTransform;
    self.contents = (__bridge id) _surface;
    IOSurfaceUnlock(_surface, 1, &_seed);
}

- (void) orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        rotateTransform = CGAffineTransformMakeRotation(RADIANS(90));
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        rotateTransform = CGAffineTransformMakeRotation(RADIANS(270));
    } else if (orientation == UIDeviceOrientationPortrait) {
        rotateTransform = CGAffineTransformMakeRotation(RADIANS(0.0));
    }
    
}




@end
