//
//  CiWindow.m
//  Cicerone
//
//  Created by Bruno on 06.02.21.
//  Copyright © 2021 Bruno Philipe. All rights reserved.
//

#import "CiWindow.h"

@interface CiWindow ()
@end

@implementation CiWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag];
	
    if (self) {
		[self sharedInit];
	}
	
    return self;
}

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag screen:(nullable NSScreen *)screen
{
	self = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag screen:screen];
	
    if (self) {
		[self sharedInit];
	}
	
    return self;
}

- (void)sharedInit
{
    self.styleMask |= NSWindowStyleMaskFullSizeContentView;
}

@end
