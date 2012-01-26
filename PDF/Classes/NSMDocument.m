//
//  NSMDocument.m
//  PDF
//
//  Created by Marc Bauer on 26.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMDocument.h"
#import "NSMPDFPageView.h"

NSString *const NSMDocumentBecameMainNotification = @"NSMDocumentBecameMainNotification";

@implementation NSMDocument
{
	IBOutlet NSMPDFPageView *_pdfPageView;
}

@synthesize pdfDocument;

#pragma mark - Initialization & Deallocation

- (void)dealloc{
	[pdfDocument release];
	[super dealloc];
}



#pragma mark - NSDocument methods

- (NSString *)windowNibName
{
	return NSStringFromClass([self class]);
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
	if (pdfDocument.numPages < 1)
    	return;
    
    _pdfPageView.page = [pdfDocument.pages objectAtIndex:0];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	pdfDocument = [[NSMPDFDocument alloc] initWithData:data];
    return pdfDocument != nil;
}

- (void)saveDocument:(id)sender{}



#pragma mark - NSWindowDelegate methods

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] 
    	postNotificationName:NSMDocumentBecameMainNotification object:self];
}
@end