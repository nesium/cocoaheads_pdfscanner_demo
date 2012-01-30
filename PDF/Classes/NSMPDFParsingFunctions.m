//
//  NSMPDFParsingFunctions.c
//  PDF
//
//  Created by Marc Bauer on 26.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage+Parsing.h"

#define NSM_CTX(page) ((NSMPDFPage *)page).context.graphicsContext

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
    CGContextAddRect(NSM_CTX(info), rect);
}

static void NSMPDF_op_rg(CGPDFScannerRef scanner, void *info)
{
	CGFloat rgb[3];
    NSMPDF_popFloats(scanner, rgb, 3);
    CGColorRef color = CGColorCreateGenericRGB(rgb[0], rgb[1], rgb[2], 1.0f);
	CGContextSetFillColorWithColor(NSM_CTX(info), color);
    CGColorRelease(color);
}

static void NSMPDF_op_f(CGPDFScannerRef scanner, void *info)
{
    CGContextClosePath(NSM_CTX(info));
    CGContextFillPath(NSM_CTX(info));
}

static void NSMPDF_op_q(CGPDFScannerRef scanner, void *info)
{
    CGContextSaveGState(NSM_CTX(info));
}

static void NSMPDF_op_Q(CGPDFScannerRef scanner, void *info)
{
    CGContextRestoreGState(NSM_CTX(info));
}

static void NSMPDF_op_cm(CGPDFScannerRef scanner, void *info)
{
    CGAffineTransform transform = NSMPDF_popMatrix(scanner);
    CGContextConcatCTM(NSM_CTX(info), transform);
}

static void NSMPDF_op_m(CGPDFScannerRef scanner, void *info)
{
    CGPoint p = NSMPDF_popPoint(scanner);
	CGContextBeginPath(NSM_CTX(info));
    CGContextMoveToPoint(NSM_CTX(info), p.x, p.y);
}

static void NSMPDF_op_l(CGPDFScannerRef scanner, void *info)
{
    CGPoint p = NSMPDF_popPoint(scanner);
    CGContextAddLineToPoint(NSM_CTX(info), p.x, p.y);
}

static void NSMPDF_op_c(CGPDFScannerRef scanner, void *info)
{
    CGPoint p = NSMPDF_popPoint(scanner);
    CGPoint cp2 = NSMPDF_popPoint(scanner);
    CGPoint cp1 = NSMPDF_popPoint(scanner);
	CGContextAddCurveToPoint(NSM_CTX(info), cp1.x, cp1.y, cp2.x, cp2.y, p.x, p.y);
}

static void NSMPDF_op_W(CGPDFScannerRef scanner, void *info)
{
    CGContextClip(NSM_CTX(info));
}

static void NSMPDF_op_n(CGPDFScannerRef scanner, void *info)
{
    if (!CGContextIsPathEmpty(NSM_CTX(info))) // omit CG warning
	    CGContextClosePath(NSM_CTX(info));
}

static void NSMPDF_op_Do(CGPDFScannerRef scanner, void *info)
{
	const char *xObjectName;
    if (!CGPDFScannerPopName(scanner, &xObjectName)){
    	NDCLog(@"Could not pop xObject name");
    }
    CGImageRef img = [(NSMPDFPage *)info copyXObjectForKey:xObjectName];
	CGContextDrawImage(NSM_CTX(info), 
	    (CGRect){CGPointZero, 1.0f, 1.0f}, img);
	CGImageRelease(img);
}

static void NSMPDF_op_Tf(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal fontSize;
    if (!CGPDFScannerPopNumber(scanner, &fontSize)){
		NDCLog(@"Could not pop font size");
        return;
    }
    
	const char *fontName;
	if (!CGPDFScannerPopName(scanner, &fontName)){
    	NDCLog(@"Could not pop font name");
    }
    
    NSMPDFFont *font = [(NSMPDFPage *)info fontForKey:fontName];
	font.size = fontSize;
    ((NSMPDFPage *)info).context.font = font;
    CGContextSetFont(NSM_CTX(info), font.CGFont);
    CGContextSetFontSize(NSM_CTX(info), fontSize);
}

static void NSMPDF_op_Tm(CGPDFScannerRef scanner, void *info)
{
    CGAffineTransform transform = NSMPDF_popMatrix(scanner);
    NSMPDFContext *ctx = ((NSMPDFPage *)info).context;
    ctx.textMatrix = ctx.lineMatrix = transform;
    CGContextSetTextMatrix(NSM_CTX(info), transform);
}

static void NSMPDF_op_Tj(CGPDFScannerRef scanner, void *info)
{
	CGPDFStringRef str;
	if (!CGPDFScannerPopString(scanner, &str)){
    	NDCLog(@"Could not pop string");
        return;
    }
	[((NSMPDFPage *)info).context.font showText:str inContext:NSM_CTX(info)];
}

static void NSMPDF_op_TJ(CGPDFScannerRef scanner, void *info)
{
	CGPDFArrayRef entries;
	if (!CGPDFScannerPopArray(scanner, &entries)){
    	NDCLog(@"Could not pop text array");
        return;
    }
    
	CGContextRef ctx = NSM_CTX(info);
    NSMPDFFont *font = ((NSMPDFPage *)info).context.font;
    
	size_t count = CGPDFArrayGetCount(entries);
	for (size_t i = 0; i < count; i++){
		CGPDFObjectRef entry;
		CGPDFArrayGetObject(entries, i, &entry);
    	
		if (CGPDFObjectGetType(entry) == kCGPDFObjectTypeString){
			CGPDFStringRef str;
			CGPDFObjectGetValue(entry, kCGPDFObjectTypeString, &str);
			[font showText:str inContext:ctx];
		}else{
        	CGPDFReal offset;
            CGPDFObjectGetValue(entry, kCGPDFObjectTypeReal, &offset);
            CGPoint pos = CGContextGetTextPosition(ctx);
            pos.x -= offset / 1000.0f;
            CGContextSetTextPosition(ctx, pos.x, pos.y);
		}
	}
}

static void NSMPDF_op_Td(CGPDFScannerRef scanner, void *info)
{
    CGPoint offset = NSMPDF_popPoint(scanner);
    NSMPDFContext *ctx = ((NSMPDFPage *)info).context;
    [ctx moveLineMatrixByOffset:offset];
    CGContextSetTextMatrix(NSM_CTX(info), ctx.textMatrix);
}

static void NSMPDF_op_TD(CGPDFScannerRef scanner, void *info)
{
    CGPoint offset = NSMPDF_popPoint(scanner);
    NSMPDFContext *ctx = ((NSMPDFPage *)info).context;
    [ctx moveLineMatrixByOffset:offset];
    ctx.leading = offset.y;
    CGContextSetTextMatrix(NSM_CTX(info), ctx.textMatrix);
}

static void NSMPDF_op_T(CGPDFScannerRef scanner, void *info)
{
    NSMPDFContext *ctx = ((NSMPDFPage *)info).context;
    [ctx moveLineMatrixByOffset:(CGPoint){0.0f, ctx.leading}];
    CGContextSetTextMatrix(NSM_CTX(info), ctx.textMatrix);
}