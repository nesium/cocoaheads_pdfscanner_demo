//
//  NSMPDFPage+Parsing.m
//  PDF
//
//  Created by Marc Bauer on 26.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFPage+Parsing.h"
#import "NSMPDFParsingFunctions.m"

@implementation NSMPDFPage (Parsing)

- (CGContextRef)context
{
	return _ctx;
}

- (void)parseResources
{
	CGPDFDictionaryRef pageDict, resourceDict;
	pageDict = CGPDFPageGetDictionary(_page);
	if (!CGPDFDictionaryGetDictionary(pageDict, "Resources", &resourceDict))
		return;
	
	CGPDFDictionaryRef xObjects;
	if (CGPDFDictionaryGetDictionary(resourceDict, "XObject", &xObjects)){
		_xObjects = xObjects;
    }
}

- (void)scanPage
{
	CGPDFOperatorTableRef op = CGPDFOperatorTableCreate();
	
    // Append rectangle to path
	CGPDFOperatorTableSetCallback(op, "re", &NSMPDF_op_re);
    // Set RGB color for nonstroking operations
	CGPDFOperatorTableSetCallback(op, "rg", &NSMPDF_op_rg);
    // Fill path using nonzero winding number rule
	CGPDFOperatorTableSetCallback(op, "f", &NSMPDF_op_f);
    // Save graphics state
	CGPDFOperatorTableSetCallback(op, "q", &NSMPDF_op_q);
    // Restore graphics state
	CGPDFOperatorTableSetCallback(op, "Q", &NSMPDF_op_Q);
    // Concatenate matrix to current transformation matrix
	CGPDFOperatorTableSetCallback(op, "cm", &NSMPDF_op_cm);
    // Begin new subpath
	CGPDFOperatorTableSetCallback(op, "m", &NSMPDF_op_m);
    // Append straight line segment to path
	CGPDFOperatorTableSetCallback(op, "l", &NSMPDF_op_l);
    // Append curved segment to path (three control points)
	CGPDFOperatorTableSetCallback(op, "c", &NSMPDF_op_c);
    
    if (self.clippingEnabled){
        // Set clipping path using nonzero winding number rule
        CGPDFOperatorTableSetCallback(op, "W", &NSMPDF_op_W);
    }
    
    // End path without filling or stroking
	CGPDFOperatorTableSetCallback(op, "n", &NSMPDF_op_n);
    // Invoke named XObject
	CGPDFOperatorTableSetCallback(op, "Do", &NSMPDF_op_Do);
	
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(_page);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, op, self);
	CGPDFScannerScan(scanner);
	CGPDFScannerRelease(scanner);
	CGPDFContentStreamRelease(contentStream);
	CGPDFOperatorTableRelease(op);
}

- (CGImageRef)copyXObjectForKey:(const char *)key
{
	CGPDFStreamRef stream;
    CGPDFDictionaryGetStream(_xObjects, key, &stream);
    CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(stream);
    
    // check if XObject is an image
    const char *name;
    if (!CGPDFDictionaryGetName(dict, "Subtype", &name))
		return nil;
    if (strcmp(name, "Image") != 0)
		return nil;
    
    // read image properties
    CGPDFInteger width, height, bps;
    if (!CGPDFDictionaryGetInteger(dict, "Width", &width))
		return nil;
    if (!CGPDFDictionaryGetInteger(dict, "Height", &height))
		return nil;
    if (!CGPDFDictionaryGetInteger(dict, "BitsPerComponent", &bps))
		return nil;
    
    // for the time being, we only support DeviceRGB and only if the colorspace is 
    // specified as a name
    const char *colorspaceName;
    if (!CGPDFDictionaryGetName(dict, "ColorSpace", &colorspaceName) || 
    	strcmp(colorspaceName, "DeviceRGB") != 0){
        NDCLog(@"Image ColorSpace not supported.");
        return nil;
    }
    
    CGPDFDataFormat format;
    CFDataRef data = CGPDFStreamCopyData(stream, &format);
    if (format != CGPDFDataFormatJPEGEncoded && format != CGPDFDataFormatJPEG2000){
    	NDCLog(@"Image data format not supported.");
        CFRelease(data);
		return nil;
    }
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    
	CGImageRef image = CGImageCreateWithJPEGDataProvider(provider, NULL, YES, 
    	kCGRenderingIntentDefault);
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    CFRelease(data);
    
    return image;
}
@end