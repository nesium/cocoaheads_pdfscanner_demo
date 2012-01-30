//
//  NSMPDFFont.m
//  PDF
//
//  Created by Marc Bauer on 28.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMPDFFont.h"

@interface NSMPDFFont ()
- (void)parseFontDictionary:(CGPDFDictionaryRef)dict;
- (void)loadGlyphList;
@end

typedef struct{
	char *glyphName;
    unichar charCode;
} NSMPDFGlyphEntry;

static size_t g_numGlyphs = 0;
static NSMPDFGlyphEntry *g_glyphList = NULL;

static int compareGlyphEntries(NSMPDFGlyphEntry a, NSMPDFGlyphEntry b)
{
	return a.charCode - b.charCode;
}


@implementation NSMPDFFont
{
	CTFontRef _CTFont;
    NSMPDFFontType _type;
    NSUInteger _firstChar;
    NSUInteger _lastChar;
    CGPDFArrayRef _differences;
}

@synthesize name, CGFont, size;

#pragma mark - Initialization & Deallocation

- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super init])){
    	_CTFont = NULL;
        _differences = NULL;
    	[self parseFontDictionary:dict];
	}
	return self;
}

- (void)dealloc
{
	[name release];
    if (_CTFont != NULL)
		CFRelease(_CTFont);
    CGFontRelease(CGFont);
	[super dealloc];
}



#pragma mark - Public methods

- (void)setSize:(CGFloat)aSize
{
	if (_CTFont != NULL && size == aSize)
    	return;
    
    if (_CTFont != NULL)
		CFRelease(_CTFont);
    
    size = aSize;
    _CTFont = CTFontCreateWithGraphicsFont(CGFont, size, NULL, NULL);
}

- (void)showText:(CGPDFStringRef)str inContext:(CGContextRef)ctx
{
	if (_type == NSMPDFFontTypeUnknown)
    	return;
    
    const char *text = (const char *)CGPDFStringGetBytePtr(str);
    size_t textLen = CGPDFStringGetLength(str);
    
    CGGlyph *glyphs = malloc(sizeof(CGGlyph) * textLen);
    
    if (_type == NSMPDFFontType1){
        if (g_glyphList == NULL)
        	[self loadGlyphList];
    	     
        for (NSUInteger i = 0; i < textLen; i++){
        	NSString *glyphName = nil;
        	
			if (_differences != NULL){
				CGPDFInteger differencesOffset;
                CGPDFArrayGetInteger(_differences, 0, &differencesOffset);
				size_t numDifferences = CGPDFArrayGetCount(_differences);
                
				for (size_t j = 1; j < numDifferences; j++){
					if (text[i] == (differencesOffset + j - 1)){
						const char *substitutedGlyphName;
						if (CGPDFArrayGetName(_differences, j, &substitutedGlyphName)){
                        	glyphName = [NSString stringWithUTF8String:substitutedGlyphName];
						}
					}
				}
            }
            
            if (glyphName == nil){
                NSMPDFGlyphEntry key = (NSMPDFGlyphEntry){NULL, text[i]};
                NSMPDFGlyphEntry *result = bsearch_b(&key, g_glyphList, g_numGlyphs, 
                    sizeof(NSMPDFGlyphEntry), ^int(const void *a, const void *b){
                        NSMPDFGlyphEntry glyphA = *(NSMPDFGlyphEntry *)a;
                        NSMPDFGlyphEntry glyphB = *(NSMPDFGlyphEntry *)b;
                        return glyphA.charCode - glyphB.charCode;
                });
                
                if (result == NULL){
                    glyphName = @".notdef";
                }else{
                    glyphName = [NSString stringWithUTF8String:(*result).glyphName];
                }
            }
            
			glyphs[i] = CGFontGetGlyphWithGlyphName(CGFont, (CFStringRef)glyphName);
        }
    }else{
        UniChar *chars = malloc(sizeof(UniChar) * textLen);
        [[NSString stringWithCString:text encoding:NSWindowsCP1252StringEncoding] 
        	getCharacters:chars];
        if (!CTFontGetGlyphsForCharacters(_CTFont, chars, glyphs, textLen))
            NDCLog(@"Could not get glyphs");
	    free(chars);
    }
    
    CGContextShowGlyphs(ctx, glyphs, textLen);
    
    free(glyphs);
}



#pragma mark - Private methods

- (void)parseFontDictionary:(CGPDFDictionaryRef)dict
{
	const char *baseFont;
    if (CGPDFDictionaryGetName(dict, "BaseFont", &baseFont)){
    	name = [[NSString alloc] initWithUTF8String:baseFont];
    }
    
    _type = NSMPDFFontTypeUnknown;
    const char *subtype;
    if (CGPDFDictionaryGetName(dict, "Subtype", &subtype)){
    	if (strcmp(subtype, "Type1") == 0){
        	_type = NSMPDFFontType1;
        }else if (strcmp(subtype, "Type3") == 0){
        	_type = NSMPDFFontType3;
        }else if (strcmp(subtype, "TrueType") == 0){
        	_type = NSMPDFFontTrueType;
        }
    }
    
    CGPDFInteger firstChar;
    if (CGPDFDictionaryGetInteger(dict, "FirstChar", &firstChar)){
    	_firstChar = firstChar;
    }
    
    CGPDFInteger lastChar;
    if (CGPDFDictionaryGetInteger(dict, "LastChar", &lastChar)){
    	_lastChar = lastChar;
    }
    
    CGPDFDictionaryRef fontDescriptor;
    if (!CGPDFDictionaryGetDictionary(dict, "FontDescriptor", &fontDescriptor)){
    	NDCLog(@"Could not read font descriptor");
        return;
    }
    
    CGPDFStreamRef stream;
    if (CGPDFDictionaryGetStream(fontDescriptor, "FontFile2", &stream) || 
    	CGPDFDictionaryGetStream(fontDescriptor, "FontFile3", &stream)){
        CFDataRef data = CGPDFStreamCopyData(stream, NULL);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGFont = CGFontCreateWithDataProvider(provider);
        CGDataProviderRelease(provider);
        CFRelease(data);
    }else{
    	NDCLog(@"Unsupported font format");
        _type = NSMPDFFontTypeUnknown;
        return;
    }
    
    CGPDFDictionaryRef encodingDict;
    if (CGPDFDictionaryGetDictionary(dict, "Encoding", &encodingDict)){
    	CGPDFArrayRef differences;
        if (CGPDFDictionaryGetArray(encodingDict, "Differences", &differences)){
        	_differences = differences;
        }
    }
}

- (void)loadGlyphList
{
	NSString *glyphListText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] 
    	pathForResource:@"glyphlist" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
	NSArray *lines = [glyphListText componentsSeparatedByCharactersInSet:
    	[NSCharacterSet newlineCharacterSet]];
    
    g_glyphList = malloc(sizeof(NSMPDFGlyphEntry) * lines.count);
    g_numGlyphs = 0;
    
	for (NSString *line in lines){
    	if ([line hasPrefix:@"#"])
        	continue;
        
        NSRange separatorRange = [line rangeOfString:@";"];
        if (separatorRange.location == NSNotFound)
        	continue;
		
        NSString *glyphName = [line substringToIndex:separatorRange.location];
        NSString *charCode = [line substringFromIndex:NSMaxRange(separatorRange)];
        uint32_t value;
    	[[NSScanner scannerWithString:charCode] scanHexInt:&value];
        
        NSMPDFGlyphEntry entry;
		entry.glyphName = malloc(sizeof(char) * glyphName.length);
        entry.charCode = (unichar)value;
        strncpy(entry.glyphName, [glyphName UTF8String], glyphName.length);
        g_glyphList[g_numGlyphs] = entry;
        
		g_numGlyphs++;
    }
    
    NSMPDFGlyphEntry *tmp = realloc(g_glyphList, sizeof(NSMPDFGlyphEntry) * g_numGlyphs);
    if (tmp == 0){
    	NDCLog(@"Could not reallocate memory");
    }else{
    	g_glyphList = tmp;
    }
    
    qsort_b(g_glyphList, g_numGlyphs, sizeof(NSMPDFGlyphEntry), ^int(const void *a, const void *b){
        NSMPDFGlyphEntry glyphA = *(NSMPDFGlyphEntry *)a;
        NSMPDFGlyphEntry glyphB = *(NSMPDFGlyphEntry *)b;
		return glyphA.charCode - glyphB.charCode;
    });
}
@end