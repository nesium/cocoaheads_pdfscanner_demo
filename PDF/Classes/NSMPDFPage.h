//
//  NSMPDFPage.h
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMPDFPage : NSObject
{
	@private
		CGPDFPageRef _page;
    	CGContextRef _ctx;
        CGPDFDictionaryRef _xObjects;
}
- (id)initWithPage:(CGPDFPageRef)page index:(NSUInteger)index;

@property (nonatomic, assign) BOOL clippingEnabled;

- (void)drawInContext:(CGContextRef)ctx;
@end