//
//  NSMPDFPage.m
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage.h"
#import "NSMPDFPage+Parsing.h"
#import "NSMPDFContext.h"

@implementation NSMPDFPage

@synthesize clippingEnabled;

#pragma mark - Initialization & Deallocation

- (id)initWithPage:(CGPDFPageRef)page index:(NSUInteger)index
{
	if ((self = [super init])){
        _page = CGPDFPageRetain(page);
        _context = nil;
        _xObjects = NULL;
        _fonts = NULL;
        _loadedFonts = nil;
	}
	return self;
}

- (void)dealloc
{
	[_loadedFonts release];
	CGPDFPageRelease(_page);
	[super dealloc];
}



#pragma mark - Public methods

- (void)drawInContext:(CGContextRef)ctx
{
	_context = [[NSMPDFContext alloc] initWithGraphicsContext:ctx];
    [self parseResources];
    [self scanPage];
	[_context release];
    _context = nil;
}
@end