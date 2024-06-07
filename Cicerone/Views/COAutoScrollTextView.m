//
//  COAutoScrollTextView.m
//  Cicerone
//
//  Created by Bruno Philipe on 6/17/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COAutoScrollTextView.h"

@implementation COAutoScrollTextView

- (void)setString:(NSString *)string
{
	[super setString:string];
	[self scrollToEndOfDocument:self];
}

@end
