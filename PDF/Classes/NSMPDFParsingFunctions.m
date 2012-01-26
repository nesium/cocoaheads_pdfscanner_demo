//
//  NSMPDFParsingFunctions.c
//  PDF
//
//  Created by Marc Bauer on 26.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage+Parsing.h"

static void NSMPDF_popFloats(CGPDFScannerRef scanner, CGFloat *buffer, NSUInteger count)
{
	for (NSInteger i = count - 1; i >= 0; i--){
    	CGPDFReal value;
        if (!CGPDFScannerPopNumber(scanner, &value)){
        	[NSException raise:@"NSMPDFParsingException" format:@"Could not pop float"];
        }
        buffer[i] = value;
    }
}

static CGPoint NSMPDF_popPoint(CGPDFScannerRef scanner)
{
	CGFloat values[2];
    NSMPDF_popFloats(scanner, values, 2);
    return *((CGPoint *)values);
}

static CGAffineTransform NSMPDF_popMatrix(CGPDFScannerRef scanner)
{
	CGFloat values[6];
    NSMPDF_popFloats(scanner, values, 6);
    return *((CGAffineTransform *)values);
}



static void NSMPDF_op_re(CGPDFScannerRef scanner, void *info)
{
	CGFloat values[4];
    NSMPDF_popFloats(scanner, values, 4);
    CGRect rect = *((CGRect *)values);
    CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGContextAddRect(ctx, rect);
}

static void NSMPDF_op_rg(CGPDFScannerRef scanner, void *info)
{
	CGFloat rgb[3];
    NSMPDF_popFloats(scanner, rgb, 3);
    CGColorRef color = CGColorCreateGenericRGB(rgb[0], rgb[1], rgb[2], 1.0f);
    CGContextRef ctx = ((NSMPDFPage *)info).context;
	CGContextSetFillColorWithColor(ctx, color);
    CGColorRelease(color);
}

static void NSMPDF_op_f(CGPDFScannerRef scanner, void *info)
{
    CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}

static void NSMPDF_op_q(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGContextSaveGState(ctx);
}

static void NSMPDF_op_Q(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGContextRestoreGState(ctx);
}

static void NSMPDF_op_cm(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGAffineTransform transform = NSMPDF_popMatrix(scanner);
    CGContextConcatCTM(ctx, transform);
}

static void NSMPDF_op_m(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGPoint p = NSMPDF_popPoint(scanner);
	CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, p.x, p.y);
}

static void NSMPDF_op_l(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGPoint p = NSMPDF_popPoint(scanner);
    CGContextAddLineToPoint(ctx, p.x, p.y);
}

static void NSMPDF_op_c(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGPoint p = NSMPDF_popPoint(scanner);
    CGPoint cp2 = NSMPDF_popPoint(scanner);
    CGPoint cp1 = NSMPDF_popPoint(scanner);
	CGContextAddCurveToPoint(ctx, cp1.x, cp1.y, cp2.x, cp2.y, p.x, p.y);
}

static void NSMPDF_op_W(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGContextClip(ctx);
}

static void NSMPDF_op_n(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
    CGContextClosePath(ctx);
}

static void NSMPDF_op_Do(CGPDFScannerRef scanner, void *info)
{
	CGContextRef ctx = ((NSMPDFPage *)info).context;
	const char *xObjectName;
	CGPDFScannerPopName(scanner, &xObjectName);
    CGImageRef img = [(NSMPDFPage *)info copyXObjectForKey:xObjectName];
	CGContextDrawImage(ctx, 
	    (CGRect){CGPointZero, 1.0f, 1.0f}, img);
	CGImageRelease(img);
}