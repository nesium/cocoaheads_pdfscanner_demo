//
//  NSMPDFFont.h
//  PDF
//
//  Created by Marc Bauer on 28.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
	NSMPDFFontType1, 
    NSMPDFFontType3, 
    NSMPDFFontTrueType, 
    NSMPDFFontTypeUnknown
} NSMPDFFontType;

@interface NSMPDFFont : NSObject
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) CGFontRef CGFont;

@property (nonatomic, assign) CGFloat size;

- (void)showText:(CGPDFStringRef)str inContext:(CGContextRef)ctx;
@end