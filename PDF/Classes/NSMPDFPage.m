//
//  NSMPDFPage.m
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage.h"
#import "NSMPDFPage+Parsing.h"

@implementation NSMPDFPage

@synthesize clippingEnabled;

#pragma mark - Initialization & Deallocation

- (id)initWithPage:(CGPDFPageRef)page index:(NSUInteger)index
{
	if ((self = [super init])){
        _page = CGPDFPageRetain(page);
	}
	return self;
}

- (void)dealloc
{
	CGPDFPageRelease(_page);
	[super dealloc];
}



#pragma mark - Public methods

- (void)drawInContext:(CGContextRef)ctx
{
	_ctx = CGContextRetain(ctx);
    [self parseResources];
    [self scanPage];
    CGContextRelease(_ctx);
    _ctx = nil;
}
@end