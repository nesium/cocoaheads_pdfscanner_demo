//
//  NSMPDFDocument.h
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMPDFDocument : NSObject
@property (nonatomic, readonly) int majorVersion;
@property (nonatomic, readonly) int minorVersion;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *author;
@property (nonatomic, readonly) NSString *subject;
@property (nonatomic, readonly) NSString *keywords;
@property (nonatomic, readonly) NSString *creator;
@property (nonatomic, readonly) NSString *producer;
@property (nonatomic, readonly) NSDate *creationDate;
@property (nonatomic, readonly) NSDate *modificationDate;

@property (nonatomic, readonly) NSUInteger numPages;

- (id)initWithFilename:(NSString *)filename;
- (id)initWithData:(NSData *)data;
@end