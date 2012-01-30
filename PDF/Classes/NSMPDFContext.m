//
//  NSMPDFContext.m
//  PDF
//
//  Created by Marc Bauer on 29.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFContext.h"

@implementation NSMPDFContext

@synthesize graphicsContext, font, textMatrix, lineMatrix, leading;

#pragma mark - Initialization & Deallocation

- (id)initWithGraphicsContext:(CGContextRef)context
{
	if ((self = [super init])){
    	graphicsContext = CGContextRetain(context);
    }
    return self;
}

- (void)dealloc
{
	CFRelease(graphicsContext);
	[font release];
    [super dealloc];
}



#pragma mark - Public methods

- (void)moveLineMatrixByOffset:(CGPoint)offset
{
    CGAffineTransform matrix = CGAffineTransformTranslate(lineMatrix, offset.x, offset.y);
    textMatrix = lineMatrix = matrix;
}
@end