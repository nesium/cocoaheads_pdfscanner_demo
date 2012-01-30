//
//  NSMPDFPage+Parsing.h
//  PDF
//
//  Created by Marc Bauer on 26.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage.h"
#import "NSMPDFFont.h"
#import "NSMPDFContext.h"

@interface NSMPDFPage (Parsing)
@property (nonatomic, readonly) NSMPDFContext *context;

- (CGImageRef)copyXObjectForKey:(const char *)key;
- (NSMPDFFont *)fontForKey:(const char *)key;

- (void)parseResources;
- (void)scanPage;
@end