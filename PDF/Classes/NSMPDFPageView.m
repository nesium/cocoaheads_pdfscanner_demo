//
//  NSMPDFPageView.m
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPageView.h"

@implementation NSMPDFPageView

@synthesize page;

#pragma mark - Public methods

- (void)setPage:(NSMPDFPage *)aPage
{
	[aPage retain];
    [page release];
    page = aPage;
    [self setNeedsDisplay:YES];
}



#pragma mark - UIView methods

- (void)drawRect:(NSRect)aRect
{
	CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
	[page drawInContext:ctx];
}
@end