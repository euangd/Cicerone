//
//  COMainWindowController.h
//  Bruh
//
//  Created by Bruno on 06.02.21.
//  Copyright © 2021 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface COMainWindowController : NSWindowController

@property (weak) IBOutlet NSScrollView *sidebarView;
@property (weak) IBOutlet NSView *windowContentView;

@property (readonly, strong) NSSplitViewController *splitViewController;

- (void)setUpViews;
- (void)setWindowContentViewHidden:(BOOL)hide;

@end

NS_ASSUME_NONNULL_END
