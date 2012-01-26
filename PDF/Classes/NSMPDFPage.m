//
//  NSMPDFPage.m
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage.h"
#import "NSMPDFParsingFunctions.m"

@implementation NSMPDFPage
{
	CGPDFPageRef _page;
}

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
	CGPDFOperatorTableRef op = CGPDFOperatorTableCreate();
	
    // Append rectangle to path
	CGPDFOperatorTableSetCallback(op, "re", &NSMPDF_op_re);
    // Set RGB color for nonstroking operations
	CGPDFOperatorTableSetCallback(op, "rg", &NSMPDF_op_rg);
    // Fill path using nonzero winding number rule
	CGPDFOperatorTableSetCallback(op, "f", &NSMPDF_op_f);
	
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(_page);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, op, ctx);
	CGPDFScannerScan(scanner);
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(op);
}
@end