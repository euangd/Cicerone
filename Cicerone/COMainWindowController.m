//
//  COMainWindowController.m
//  Cicerone
//
//  Created by Bruno on 06.02.21.
//  Copyright © 2021 Bruno Philipe. All rights reserved.
//

#import "COMainWindowController.h"
#import "NSLayoutConstraint+Shims.h"
#import "COWindow.h"

@interface COMainWindowController ()

@property (strong) NSSplitViewController *splitViewController;

@end

@implementation COMainWindowController

- (void)setUpViews
{
	_splitViewController = [[NSSplitViewController alloc] initWithNibName:nil bundle:nil];

	[_splitViewController addSplitViewItem:[self makeSidebarSplitViewItem]];
	[_splitViewController addSplitViewItem:[self makeContentSplitViewItem]];

	NSView *splitControllerView = [[self splitViewController] view];
	NSView *windowContentView = [[self window] contentView];
    
    NSAssert(splitControllerView, @"View should not be nil");
    NSAssert(windowContentView, @"View should not be nil");
    
    splitControllerView.translatesAutoresizingMaskIntoConstraints = NO;
    [windowContentView addSubview:splitControllerView];

	[NSLayoutConstraint activate:@[
		[NSLayoutConstraint constraintWithItem:splitControllerView 
                                     attribute:NSLayoutAttributeLeading 
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:windowContentView
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:splitControllerView 
                                     attribute:NSLayoutAttributeTrailing 
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:windowContentView
                                     attribute:NSLayoutAttributeTrailing
                                    multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:splitControllerView 
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:windowContentView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:splitControllerView 
                                     attribute:NSLayoutAttributeBottom 
                                     relatedBy:NSLayoutRelationEqual 
                                        toItem:windowContentView
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1 constant:0]
	]];
}

- (void)setWindowContentViewHidden:(BOOL)hide
{
    self.windowContentView.hidden = hide;
}

- (NSSplitViewItem *)makeSidebarSplitViewItem
{
	NSViewController *sidebarViewController = [[NSViewController alloc] initWithNibName:nil bundle:nil];
    sidebarViewController.view = self.sidebarView;
    
    NSSplitViewItem *sidebarSplitViewItem = [NSSplitViewItem sidebarWithViewController:sidebarViewController];
    sidebarSplitViewItem.minimumThickness = 250;

	return sidebarSplitViewItem;
}

- (NSSplitViewItem *)makeContentSplitViewItem
{
	NSViewController *contentViewController = [[NSViewController alloc] initWithNibName:nil bundle:nil];
    contentViewController.view = self.windowContentView;

	return [NSSplitViewItem splitViewItemWithViewController:contentViewController];
}

@end
