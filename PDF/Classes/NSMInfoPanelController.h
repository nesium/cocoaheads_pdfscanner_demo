//
//  NSMMainWindowViewController.h
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSMPDFDocument.h"

@interface NSMInfoPanelController : NSWindowController
@property (nonatomic, retain) NSMPDFDocument *pdfDocument;
@end