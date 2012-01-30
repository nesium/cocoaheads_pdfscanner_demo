//
//  NSMPDFPage.h
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSMPDFFont;
@class NSMPDFContext;

@interface NSMPDFPage : NSObject
{
	@private
		CGPDFPageRef _page;
        CGPDFDictionaryRef _xObjects;
        CGPDFDictionaryRef _fonts;
        NSMutableDictionary *_loadedFonts;
        NSMPDFContext *_context;
}
- (id)initWithPage:(CGPDFPageRef)page index:(NSUInteger)index;

@property (nonatomic, assign) BOOL clippingEnabled;

- (void)drawInContext:(CGContextRef)ctx;
@end