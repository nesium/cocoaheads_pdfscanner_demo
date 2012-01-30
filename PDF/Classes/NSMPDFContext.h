//
//  NSMPDFContext.h
//  PDF
//
//  Created by Marc Bauer on 29.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSMPDFFont.h"

@interface NSMPDFContext : NSObject
- (id)initWithGraphicsContext:(CGContextRef)context;

@property (nonatomic, readonly) CGContextRef graphicsContext;
@property (nonatomic, retain) NSMPDFFont *font;
@property (nonatomic, assign) CGAffineTransform textMatrix;
@property (nonatomic, assign) CGAffineTransform lineMatrix;
@property (nonatomic, assign) CGFloat leading;

- (void)moveLineMatrixByOffset:(CGPoint)offset;
@end