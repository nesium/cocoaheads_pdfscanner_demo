//
//  NSMPDFDocument.m
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFDocument.h"
#import "NSMPDFPage.h"

@interface NSMPDFDocument ()
- (id)initWithCGPDFDocument:(CGPDFDocumentRef)document;
- (void)loadDocumentInfo;
@end


@implementation NSMPDFDocument
{
	CGPDFDocumentRef _pdf;
    NSArray *_pages;
}

@synthesize minorVersion, majorVersion, title, author, subject, keywords, creator, producer, 
	creationDate, modificationDate;

#pragma mark - Initialization & Deallocation

- (id)initWithFilename:(NSString *)filename
{
    NSURL *fileURL = [NSURL fileURLWithPath:filename isDirectory:NO];
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL((CFURLRef)fileURL);
    
	self = [self initWithCGPDFDocument:document];
    if (document != NULL){
        CFRelease(document);
    }
	return self;
}

- (id)initWithData:(NSData *)data
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(dataProvider);
    CFRelease(dataProvider);
	
	self = [self initWithCGPDFDocument:document];
    if (document != NULL){
        CFRelease(document);
    }
	return self;
}

- (id)initWithCGPDFDocument:(CGPDFDocumentRef)document
{
    if ((self = [super init])){
        if (document == NULL){
			NSLog(@"Could not open PDF");
            return nil;
        }else{
            _pdf = CGPDFDocumentRetain(document);
            [self loadDocumentInfo];
        }
    }
    return self;
}

- (void)dealloc
{
	[_pages release];
	CGPDFDocumentRelease(_pdf);
    [title release];
    [author release];
    [subject release];
    [keywords release];
    [creator release];
    [producer release];
    [creationDate release];
    [modificationDate release];
    [super dealloc];
}



#pragma mark - Public methods

- (NSUInteger)numPages
{
	return CGPDFDocumentGetNumberOfPages(_pdf);
}

- (NSArray *)pages
{
	if (!_pages){
    	NSMutableArray *pages = [NSMutableArray arrayWithCapacity:self.numPages];
    	for (NSInteger i = 1; i <= self.numPages; i++){
			NSMPDFPage *page = [[NSMPDFPage alloc] initWithPage:CGPDFDocumentGetPage(_pdf, i) 
            	index:i];
			[pages addObject:page];
        }
        _pages = [pages copy];
    }
    return _pages;
}



#pragma mark - Private methods

- (void)loadDocumentInfo
{
	CGPDFDocumentGetVersion(_pdf, &majorVersion, &minorVersion);
	CGPDFDictionaryRef infoDict = CGPDFDocumentGetInfo(_pdf);
	CGPDFStringRef str;
	if (CGPDFDictionaryGetString(infoDict, "Title", &str))
		title = (NSString *)CGPDFStringCopyTextString(str);
	if (CGPDFDictionaryGetString(infoDict, "Author", &str))
		author = (NSString *)CGPDFStringCopyTextString(str);
	if (CGPDFDictionaryGetString(infoDict, "Subject", &str))
		subject = (NSString *)CGPDFStringCopyTextString(str);
	if (CGPDFDictionaryGetString(infoDict, "Keywords", &str))
		keywords = (NSString *)CGPDFStringCopyTextString(str);
	if (CGPDFDictionaryGetString(infoDict, "Creator", &str))
		creator = (NSString *)CGPDFStringCopyTextString(str);
	if (CGPDFDictionaryGetString(infoDict, "Producer", &str))
		producer = (NSString *)CGPDFStringCopyTextString(str);
	if (CGPDFDictionaryGetString(infoDict, "CreationDate", &str))
		creationDate = (NSDate *)CGPDFStringCopyDate(str);
	if (CGPDFDictionaryGetString(infoDict, "ModDate", &str))
		modificationDate = (NSDate *)CGPDFStringCopyDate(str);
}
@end