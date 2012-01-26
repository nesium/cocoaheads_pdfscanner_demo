//
//  NSMMainWindowViewController.m
//  PDF
//
//  Created by Marc Bauer on 25.01.12.
//  Copyright (c) 2012 nesiumdotcom. All rights reserved.
//

#import "NSMInfoPanelController.h"

@implementation NSMInfoPanelController

@synthesize pdfDocument;

#pragma mark - Initialization & Deallocation

- (id)init
{
	if ((self = [super initWithWindowNibName:@"InfoPanel"])){
	}
	return self;
}

- (void)dealloc
{
	[pdfDocument release];
	[super dealloc];
}
@end