//
//  CiToolbar.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 16/08/15.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.	If not, see <http://www.gnu.org/licenses/>.
//

#import "CiToolbar.h"
#import "CiStyle.h"
#import "CiAppDelegate.h"

static NSString *kToolbarIdentifier = @"toolbarIdentifier";

static NSString *kToolbarItemHomebrewUpdateIdentifier = @"toolbarItemHomebrewUpdate";
static NSString *kToolbarItemInformationIdentifier = @"toolbarItemInformation";
static NSString *kToolbarItemSearchIdentifier = @"toolbarItemSearch";
static NSString *kToolbarItemMultiActionIdentifier = @"toolbarItemMultiAction";

@interface CiToolbar() <NSSearchFieldDelegate>

@property (assign) CiBarUses barUse;
@property (strong) NSSearchField *searchField;

@end

@implementation CiToolbar

- (instancetype)initWithIdentifier:(NSString *)identifier
{
	self = [super initWithIdentifier:kToolbarIdentifier];
    
	if (self)
	{
		[self setSizeMode:[CiStyle toolbarSize]];
		
		_barUse = CiBarBlank;
        
		[self setToolsWithUse:CiBarCore];
		[self lock:YES];
		[self setAllowsUserCustomization:YES];
	}
    
	return self;
}

- (void)setToolsWithUse:(CiBarUses)intent
{
	if (self.barUse == intent)
	{
		return;
	}
	
	self.barUse = intent;
	NSToolbarItem *localInformationItem = [self informationItem];
	
	if (intent == CiBarAddTapMode || intent == CiBarTapMode || intent == CiOBarUAIActOnOldVersionsInstalled || intent == CiBarCore)
	{
		// will force toolbar to show empty nonclickable item
		[self customizeItem:localInformationItem withVisual:nil withLabel:nil withAction:nil];
	}
	else
	{
		[self customizeItem:localInformationItem withVisual:[CiStyle toolbarImageForMoreInformation] withLabel:NSLocalizedString(@"Toolbar_More_Information", nil) withAction:@selector(showFormulaInfo:)];
	}
	
	NSToolbarItem *localVariedActionsItem = [self variedActionsItem];

	switch (intent) {
        case CiBarCore:
            [self customizeItem:localVariedActionsItem withVisual:nil withLabel:nil withAction:nil];
            break;
            
        case CiOBarUAIActOnInstallable:
            [self customizeItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForInstall] withLabel:NSLocalizedString(@"Toolbar_Install_Formula", nil) withAction:@selector(installFormula:)];
            break;
            
        case CiOBarUAIActOnInstalled:
            [self customizeItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUninstall] withLabel:NSLocalizedString(@"Toolbar_Uninstall_Formula", nil) withAction:@selector(uninstallFormula:)];
            break;
            
        case CiBarAddTapMode:
            [self customizeItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForTap] withLabel:NSLocalizedString(@"Toolbar_Tap_Repo", nil) withAction:@selector(tapRepository:)];
            break;
            
        case CiBarTapMode:
            [self customizeItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUntap] withLabel:NSLocalizedString(@"Toolbar_Untap_Repo", nil) withAction:@selector(untapRepository:)];
            break;
            
        case CiOBarUAIActOnOldVersionInstalled:
            [self customizeItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUpdate] withLabel:NSLocalizedString(@"Toolbar_Update_Formula", nil) withAction:@selector( upgradeSelectedFormulae:)];
            break;
            
        case CiOBarUAIActOnOldVersionsInstalled:
            [self customizeItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUpdate] withLabel:NSLocalizedString(@"Toolbar_Update_Selected", nil) withAction:@selector(upgradeSelectedFormulae:)];
            break;
            
        default:
            break;
	}
    
	[self validateVisibleItems];
}

- (void)setActiveVisualContext:(id)controller
{
	if (_activeVisualContext != controller)
	{
		_activeVisualContext = controller;
	}
}

- (void)setToolBarItemsController:(id)controller
{
	NSDictionary *supportedItems = [self customToolbarItems];
	[supportedItems enumerateKeysAndObjectsUsingBlock:^(id key, NSToolbarItem *object, BOOL *stop){
        [object setTarget:controller];
        [object setEnabled:controller != nil]; // Disables the searchbox toolbar item
	}];
}

- (void)lock:(BOOL)shouldFreeze
{
    [self setToolBarItemsController: shouldFreeze ? nil : _activeVisualContext];
    [self validateVisibleItems];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSDictionary *supportedItems = [self customToolbarItems];
    
	if (![supportedItems objectForKey:itemIdentifier])
	{
		return nil;
	}
    
	return supportedItems[itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	if (@available(macOS 11.0, *)) {
		return @[
            NSToolbarFlexibleSpaceItemIdentifier,
            kToolbarItemHomebrewUpdateIdentifier,
            NSToolbarSidebarTrackingSeparatorItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            kToolbarItemMultiActionIdentifier,
            kToolbarItemInformationIdentifier,
            kToolbarItemSearchIdentifier,
		];
	} else {
        return @[
            kToolbarItemHomebrewUpdateIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            kToolbarItemMultiActionIdentifier,
            kToolbarItemInformationIdentifier,
            kToolbarItemSearchIdentifier,
        ];
	}
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	NSArray *systemToolbarItems = [self systemToolbarItems];
	NSArray *customToolbarItems = @[
        kToolbarItemHomebrewUpdateIdentifier,
        kToolbarItemInformationIdentifier,
        kToolbarItemSearchIdentifier,
        kToolbarItemMultiActionIdentifier
    ];
	return [systemToolbarItems arrayByAddingObjectsFromArray:customToolbarItems];
}

- (NSArray *)systemToolbarItems
{
	static NSArray *systemToolbarItems = nil;
    
	if (!systemToolbarItems)
	{
		if (@available(macOS 11.0, *)) {
			systemToolbarItems = @[
				NSToolbarSpaceItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarSidebarTrackingSeparatorItemIdentifier,
				NSToolbarSeparatorItemIdentifier
			];
		} else {
			systemToolbarItems = @[
				NSToolbarSpaceItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarSeparatorItemIdentifier
			];
		}
	}
    
	return systemToolbarItems;
}

- (NSDictionary *)customToolbarItems
{
	static NSDictionary *customToolbarItems = nil;
    
	if (!customToolbarItems)
	{
		customToolbarItems = @{
            kToolbarItemHomebrewUpdateIdentifier : [self toolbarItemHomebrewUpdate],
            kToolbarItemInformationIdentifier : [self informationItem],
            kToolbarItemSearchIdentifier : [self searchItem],
            kToolbarItemMultiActionIdentifier : [self variedActionsItem]
        };
	}
    
	return customToolbarItems;
}

- (NSToolbarItem *)toolbarItemHomebrewUpdate
{
	static NSToolbarItem* toolbarItemHomebrewUpdate = nil;
    
	if (!toolbarItemHomebrewUpdate)
	{
		toolbarItemHomebrewUpdate = [self toolbarItemWithIdentifier:kToolbarItemHomebrewUpdateIdentifier image:[CiStyle toolbarImageForUpgrade] label:NSLocalizedString(@"Toolbar_Homebrew_Update", nil) action:@selector(updateHomebrew:)];
	}
    
	return toolbarItemHomebrewUpdate;
}

- (NSToolbarItem *)informationItem
{
	static NSToolbarItem* toolbarItemInformation = nil;
    
	if (!toolbarItemInformation)
	{
		toolbarItemInformation = [self toolbarItemWithIdentifier:kToolbarItemInformationIdentifier image:[CiStyle toolbarImageForMoreInformation] label:NSLocalizedString(@"Toolbar_More_Information", nil) action:@selector(showFormulaInfo:)];
	}
    
	return toolbarItemInformation;
}


- (NSToolbarItem *)variedActionsItem
{
	static NSToolbarItem* toolbarItemMultiAction = nil;
    
	if (!toolbarItemMultiAction)
	{
		toolbarItemMultiAction = [self toolbarItemWithIdentifier:kToolbarItemMultiActionIdentifier image:nil label:nil action:nil];
	}
    
	return toolbarItemMultiAction;
}

- (NSToolbarItem *)searchItem
{
	static NSToolbarItem* localSearchItem = nil;
    
	if (!localSearchItem)
	{
		if (@available(macOS 11.0, *))
        {
			localSearchItem = [[NSSearchToolbarItem alloc] initWithItemIdentifier:kToolbarItemSearchIdentifier];
		}
        else
        {
			localSearchItem = [[NSToolbarItem alloc] initWithItemIdentifier:kToolbarItemSearchIdentifier];
		}
        
		localSearchItem.label = NSLocalizedString(@"Toolbar_Search", nil);
		localSearchItem.paletteLabel = NSLocalizedString(@"Toolbar_Search", nil);
		localSearchItem.action = @selector(performSearchWithString:);
		
		self.searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
		self.searchField.delegate = self;
		self.searchField.continuous = YES;
		[self.searchField setRecentsAutosaveName:@"RecentSearches"];

		if (@available(macOS 11.0, *))
        {
			[(NSSearchToolbarItem *)localSearchItem setSearchField:self.searchField];
		}
        else
        {
			[localSearchItem setView:self.searchField];
		}
	}
    
	return localSearchItem;
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier image:(NSImage *)image label:(NSString *)label action:(SEL)action
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    
	if (@available(macOS 11.0, *))
    {
		item.view = [self buttonWithVisual:image andReceiver:[self activeVisualContext] forAction:action];
	}
    else
    {
		item.image = image;
		item.target = [self activeVisualContext];
	}
    
	item.label = label;
	item.paletteLabel = label;
	item.action = action;
	item.autovalidates = YES;
	item.toolTip = label;
    
	return item;
}

- (void)customizeItem:(NSToolbarItem *)item withVisual:(NSImage *)visual withLabel:(NSString *)label withAction:(SEL)action
{
	assert([NSThread isMainThread]);

	static BOOL (^staticBlock)(NSRect) = ^BOOL(NSRect dstRect)
    {
		return YES;
	};
	
	if (!visual)
    {
        item.view = nil;
		item.action = action;
	}
    else
    {
		if (@available(macOS 11.0, *))
        {
			item.view = [self buttonWithVisual:visual andReceiver:[self activeVisualContext] forAction:action];
		}
        else
        {
			item.image = visual;
			item.action = action;
		}
	}

	item.label = label;
	item.toolTip = label;
}

- (NSButton *)buttonWithVisual:(NSImage *)visual andReceiver:(id)receiver forAction:(SEL)action
{
	if (visual == nil)
    {
		return nil;
	}
    
    NSButton *button = [NSButton buttonWithImage:visual target:receiver action:action];
    [button setBezelStyle:NSBezelStyleTexturedRounded];
    [button setButtonType:NSButtonTypeMomentaryPushIn];
    [button setBordered:YES];
    [button setAlignment:NSTextAlignmentCenter];
	
    return button;
}

- (void)showSearch
{
	NSView *searchView;

	if (@available(macOS 11.0, *))
    {
		searchView = [(NSSearchToolbarItem *)[self searchItem] searchField];
	}
    else
    {
		searchView = [[self searchItem] view];
	}

	[[searchView window] makeFirstResponder:searchView];
}

#pragma mark - NSTextField Delegate
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSSearchField *field = (NSSearchField *)[aNotification object];
	[self.activeVisualContext performSearchWithString:field.stringValue];
}

@end
