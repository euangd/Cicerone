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

// keeping the values the same in case they are used in XIB, todo: check this; seems to be overridden here in init code versus the value given from HomebrewViewController

static NSString *kToolbarIdentifier = @"toolbarIdentifier";

static NSString *kToolbarItemBrewUpdateToolIdentifier = @"toolbarItemHomebrewUpdate";
static NSString *kToolbarItemBrewInfoToolIdentifier = @"toolbarItemInformation";
static NSString *kToolbarItemSearchIdentifier = @"toolbarItemSearch";
static NSString *kToolbarItemMultiActionIdentifier = @"toolbarItemMultiAction";

@interface CiToolbar() <NSSearchFieldDelegate, NSToolbarItemValidation>

@property (strong) NSSearchField *searchField;

@property (nonatomic) NSArray *systemToolbarItemIdentifiers;
@property (nonatomic, strong) NSDictionary<NSString *, NSToolbarItem *> *customToolbarItemsLookup;

@property (nonatomic) NSToolbarItem *brewUpdateToolToolbarItem, *brewInfoToolToolbarItem, *multiActionToolbarItem;
@property (nonatomic) NSSearchToolbarItem *searchToolbarItem;

@end

@implementation CiToolbar

- (instancetype)initWithIdentifier:(NSString *)identifier
{
	self = [super initWithIdentifier:kToolbarIdentifier];
    
	if (self)
	{
        self.sizeMode = [CiStyle toolbarSize];
        self.showsBaselineSeparator = NO;

        self.delegate = self;
        
        _mode = (CiToolbarMode)-1;
        self.mode = kCiToolbarModeDud;
	}
    
	return self;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    switch (self.mode) {
        case kCiToolbarModeDud:
            return NO;
    }
    
    if ([item.itemIdentifier isEqualToString:kToolbarItemBrewInfoToolIdentifier]) {
        switch (self.mode) {
        case kCiToolbarModeCore:
        case kCiToolbarModeTap:
        case kCiToolbarModeTappedRepository:
            return NO;
        }
    } else if ([item.itemIdentifier isEqualToString:kToolbarItemMultiActionIdentifier]) {
        switch (self.mode) {
            case kCiToolbarModeCore:
                return NO;
        }
    }
    
    return item.enabled = YES;
}

- (void)disableToolbarItem:(NSToolbarItem *)item withTarget:(id)target withValidation:(BOOL)valid
{
    // autovalidate will cause the item to be disabled when it does not have both a valid target and selector
    // abusing autovalidate here is holdover from older logic, which was only used to lock the whole toolbar by doing this for each item
    // the current code not only does item disabling via autovalidate with target but also uses -[NSToolbarItemValidation validateToolbarItem:] to determine visibility automatically when the framework requests it, but
    //  visibility only ever changes if the mode changes
    // so maybe investigate either not using mode, and getting rid of autovalidate (because it doesn't even do search bar validation)
    
    // side note that side bar validation is done via mode.
    // another side note that autovalidation-only mode-setting instant validation must be done via -[NSApp updateWindows], and again, cannot validate the search bar
    
    item.target = valid ? target : nil;
    item.enabled = valid;
}

- (void)setMode:(CiToolbarMode)mode
{
	@synchronized (self) {
        if (self.mode == mode)
        {
            return;
        }
        
        _mode = mode;
        [self actualizeToolbarItems];
        
        [NSApp updateWindows];
    }
}

- (void)validateVisibleItems
{
    [super validateVisibleItems];
    
    [self.visibleItems enumerateObjectsUsingBlock:^(__kindof NSToolbarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self disableToolbarItem:obj withTarget:_homebrewViewController withValidation:[self validateToolbarItem:obj]];
    }];
}

- (void)actualizeToolbarItems
{
    [self.visibleItems enumerateObjectsUsingBlock:^(__kindof NSToolbarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self actualizeToolbarItem:obj];
    }];
    
    [self validateVisibleItems];
}

- (void)actualizeToolbarItem:(NSToolbarItem *)item
{
    if ([item.itemIdentifier isEqualToString:kToolbarItemMultiActionIdentifier]) {
        switch (self.mode) {
            case kCiToolbarModeNotInstalledPackage:
                [self modifyToolbarItem:_multiActionToolbarItem withVisual:[CiStyle toolbarImageForInstall] withLabel:NSLocalizedString(@"Toolbar_Install_Formula", nil)
                             withAction:@selector(installSelectedFormula:)];
                break;
                
            case kCiToolbarModeInstalledPackage:
                [self modifyToolbarItem:_multiActionToolbarItem withVisual:[CiStyle toolbarImageForUninstall] withLabel:NSLocalizedString(@"Toolbar_Uninstall_Formula", nil)
                             withAction:@selector(uninstallSelectedFormula:)];
                break;
                
            case kCiToolbarModeTap:
                [self modifyToolbarItem:_multiActionToolbarItem withVisual:[CiStyle toolbarImageForTap] withLabel:NSLocalizedString(@"Toolbar_Tap_Repo", nil)
                             withAction:@selector(tap:)];
                break;
                
            case kCiToolbarModeTappedRepository:
                [self modifyToolbarItem:_multiActionToolbarItem withVisual:[CiStyle toolbarImageForUntap] withLabel:NSLocalizedString(@"Toolbar_Untap_Repo", nil)
                             withAction:@selector(untapSelectedRepository:)];
                break;
                
            case kCiToolbarModeOutdatedPackage:
                [self modifyToolbarItem:_multiActionToolbarItem withVisual:[CiStyle toolbarImageForUpdate] withLabel:NSLocalizedString(@"Toolbar_Update_Selected", nil) // Toolbar_Update_Formula
                             withAction:@selector(upgradeSelectedFormulae:)];
                break;
                
            default:
                [self modifyToolbarItem:_multiActionToolbarItem withVisual:[CiStyle toolbarImageForInstall] withLabel:@"Add Item"
                             withAction:@selector(installSelectedFormula:)];
                break;
        }
    }
}

// NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	if (![self.customToolbarItemsLookup objectForKey:itemIdentifier])
	{
		return nil;
	}
    
	return self.customToolbarItemsLookup[itemIdentifier];
}

// NSToolbar

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[
        NSToolbarFlexibleSpaceItemIdentifier,
        kToolbarItemBrewUpdateToolIdentifier,
        NSToolbarSidebarTrackingSeparatorItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kToolbarItemMultiActionIdentifier,
        kToolbarItemBrewInfoToolIdentifier,
        kToolbarItemSearchIdentifier,
    ];
}

// NSToolbar

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [self.systemToolbarItemIdentifiers arrayByAddingObjectsFromArray:@[
        kToolbarItemBrewUpdateToolIdentifier,
        kToolbarItemBrewInfoToolIdentifier,
        kToolbarItemSearchIdentifier,
        kToolbarItemMultiActionIdentifier
    ]];
}

- (NSArray *)systemToolbarItemIdentifiers
{
	if (!_systemToolbarItemIdentifiers) {
        _systemToolbarItemIdentifiers = @[
            NSToolbarSpaceItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarSidebarTrackingSeparatorItemIdentifier,
            NSToolbarSeparatorItemIdentifier
        ];
    }
    
	return _systemToolbarItemIdentifiers;
}

- (NSDictionary *)customToolbarItemsLookup
{
	if (!_customToolbarItemsLookup)
	{
		_customToolbarItemsLookup = @{
            kToolbarItemBrewUpdateToolIdentifier :self.brewUpdateToolToolbarItem,
            kToolbarItemBrewInfoToolIdentifier : self.brewInfoToolToolbarItem,
            kToolbarItemSearchIdentifier : self.searchToolbarItem,
            kToolbarItemMultiActionIdentifier : self.multiActionToolbarItem
        };
	}
    
	return _customToolbarItemsLookup;
}

- (NSToolbarItem *)brewUpdateToolToolbarItem
{
	if (!_brewUpdateToolToolbarItem)
	{
        _brewUpdateToolToolbarItem = [self toolbarItemWithIdentifier:kToolbarItemBrewUpdateToolIdentifier
                                                          withVisual:[CiStyle toolbarImageForUpgrade]
                                                    withPaletteLabel:NSLocalizedString(@"Toolbar_Homebrew_Update", nil)
                                                          withAction:@selector(update:)];
	}
    
	return _brewUpdateToolToolbarItem;
}

- (NSToolbarItem *)brewInfoToolToolbarItem
{
	if (!_brewInfoToolToolbarItem)
	{
		_brewInfoToolToolbarItem = [self toolbarItemWithIdentifier:kToolbarItemBrewInfoToolIdentifier
                                                        withVisual:[CiStyle toolbarImageForMoreInformation]
                                                  withPaletteLabel:NSLocalizedString(@"Toolbar_More_Information", nil)
                                                        withAction:@selector(infoForSelectedFormula:)];
	}
    
	return _brewInfoToolToolbarItem;
}


- (NSToolbarItem *)multiActionToolbarItem
{
    if (!_multiActionToolbarItem)
    {
        _multiActionToolbarItem = [self toolbarItemWithIdentifier:kToolbarItemMultiActionIdentifier withVisual:nil withPaletteLabel:nil withAction:nil];
        [self actualizeToolbarItem:_multiActionToolbarItem];
    }
    
	return _multiActionToolbarItem;
}

- (NSSearchToolbarItem *)searchToolbarItem
{
	if (!_searchToolbarItem)
	{
        _searchToolbarItem = [[NSSearchToolbarItem alloc] initWithItemIdentifier:kToolbarItemSearchIdentifier];
        
		_searchToolbarItem.label = NSLocalizedString(@"Toolbar_Search", nil);
		_searchToolbarItem.paletteLabel = NSLocalizedString(@"Toolbar_Search", nil);
        
		_searchToolbarItem.action = @selector(performSearchWithString:);
		
		self.searchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
		self.searchField.delegate = self;
		self.searchField.continuous = YES;
        self.searchField.recentsAutosaveName = @"RecentSearches";
        
        _searchToolbarItem.searchField = self.searchField;
	}
    
	return _searchToolbarItem;
}

- (void)showSearch
{
	NSView *searchView = self.searchToolbarItem.searchField;
	[[searchView window] makeFirstResponder:searchView];
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier withVisual:(NSImage *)image withPaletteLabel:(NSString *)label withAction:(SEL)action
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    
    item.autovalidates = YES;
    
    item.paletteLabel = label;
    item.bordered = YES;
    
    [self modifyToolbarItem:item withVisual:image withLabel:label withAction:action];
    
    return item;
}

- (void)modifyToolbarItem:(NSToolbarItem *)item withVisual:(NSImage *)visual withLabel:(NSString *)label withAction:(SEL)action
{
    assert([NSThread isMainThread]);

    item.image = visual;
    
    item.target = _homebrewViewController;
    item.action = action;
    
    item.label = label;
    item.toolTip = label;
}

#pragma mark - NSTextField Delegate
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSSearchField *field = (NSSearchField *)[aNotification object];
	[self.homebrewViewController performSearchWithString:field.stringValue];
}

@end
