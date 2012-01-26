//
//  NSMPDFParsingFunctions.c
//  PDF
//
//  Created by Marc Bauer on 26.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

static void NSMPDF_op_re(CGPDFScannerRef scanner, void *info)
{
	CGFloat rectValues[4];
    for (int i = 3; i >= 0; i--){
    	CGPDFReal value;
        if (!CGPDFScannerPopNumber(scanner, &value)){
        	NDCLog(@"Could not pop rect.");
            return;
        }
		rectValues[i] = value;
    }
    
    CGRect rect = *((CGRect *)rectValues);
    CGContextRef ctx = (CGContextRef)info;
    CGContextAddRect(ctx, rect);
}

static void NSMPDF_op_rg(CGPDFScannerRef scanner, void *info)
{
	CGFloat rgb[3];
    for (int i = 2; i >= 0; i--){
    	CGPDFReal value;
        if (!CGPDFScannerPopNumber(scanner, &value)){
        	NDCLog(@"Could not pop RGB color.");
            return;
        }
		rgb[i] = value;
    }
    
    CGColorRef color = CGColorCreateGenericRGB(rgb[0], rgb[1], rgb[2], 1.0f);
    CGContextRef ctx = (CGContextRef)info;
	CGContextSetFillColorWithColor(ctx, color);
    CGColorRelease(color);
}

static void NSMPDF_op_f(CGPDFScannerRef scanner, void *info)
{
    CGContextRef ctx = (CGContextRef)info;
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}