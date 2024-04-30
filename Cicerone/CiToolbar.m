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

@interface CiToolbar() <NSSearchFieldDelegate>

@property (strong) NSSearchField *searchField;

@property (readonly) NSArray *systemToolbarItemIdentifiers;
@property (readonly) NSDictionary *customToolbarItemIdentifierToolbarItemLookupDictionary;

@property (readonly) NSToolbarItem *brewUpdateToolToolbarItem, *brewInfoToolToolbarItem, *multiActionToolbarItem;
@property (readonly) NSSearchToolbarItem *searchToolbarItem;

@end

@implementation CiToolbar

- (instancetype)initWithIdentifier:(NSString *)identifier
{
	self = [super initWithIdentifier:kToolbarIdentifier];
    
	if (self)
	{
        self.sizeMode = [CiStyle toolbarSize];
		
		_mode = kCiToolbarModeBlank;
        
        self.mode = kCiToolbarModeCore;
		[self setLock:YES];
		[self setAllowsUserCustomization:YES];
	}
    
	return self;
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier withVisual:(NSImage *)image withLabel:(NSString *)label withAction:(SEL)action
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    
    [self modifyToolbarItem:item withVisual:image withLabel:label withAction:action];
    
    item.paletteLabel = label;
    
    item.autovalidates = YES;
    
    return item;
}

- (void)setMode:(CiLToolbarMode)mode
{
	@synchronized (self) {
        if (self.mode == mode)
        {
            return;
        }
        
        _mode = mode;
        NSToolbarItem *brewInfoToolToolbarItem = self.brewInfoToolToolbarItem;
        
        if (mode == kCiToolbarModeTap || mode == kCiToolbarModeTappedRepository || mode == kCiToolbarModeOutdatedPackages || mode == kCiToolbarModeCore)
        {
            // will force toolbar to show empty nonclickable item
            [self modifyToolbarItem:brewInfoToolToolbarItem withVisual:nil withLabel:nil withAction:nil];
        }
        else
        {
            [self modifyToolbarItem:brewInfoToolToolbarItem withVisual:[CiStyle toolbarImageForMoreInformation] withLabel:NSLocalizedString(@"Toolbar_More_Information", nil) withAction:@selector(infoForSelectedFormula:)];
        }
        
        NSToolbarItem *localVariedActionsItem = [self multiActionToolbarItem];

        switch (mode) {
            case kCiToolbarModeCore:
                [self modifyToolbarItem:localVariedActionsItem withVisual:nil withLabel:nil withAction:nil];
                break;
                
            case kCiToolbarModeNotInstalledPackage:
                [self modifyToolbarItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForInstall] withLabel:NSLocalizedString(@"Toolbar_Install_Formula", nil) withAction:@selector(installSelectedFormula:)];
                break;
                
            case kCiToolbarModeInstalledPackage:
                [self modifyToolbarItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUninstall] withLabel:NSLocalizedString(@"Toolbar_Uninstall_Formula", nil) withAction:@selector(uninstallSelectedFormula:)];
                break;
                
            case kCiToolbarModeTap:
                [self modifyToolbarItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForTap] withLabel:NSLocalizedString(@"Toolbar_Tap_Repo", nil) withAction:@selector(tap:)];
                break;
                
            case kCiToolbarModeTappedRepository:
                [self modifyToolbarItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUntap] withLabel:NSLocalizedString(@"Toolbar_Untap_Repo", nil) withAction:@selector(untapSelectedRepository:)];
                break;
                
            case kCiToolbarModeOutdatedPackage:
                [self modifyToolbarItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUpdate] withLabel:NSLocalizedString(@"Toolbar_Update_Formula", nil) withAction:@selector( upgradeSelectedFormulae:)];
                break;
                
            case kCiToolbarModeOutdatedPackages:
                [self modifyToolbarItem:localVariedActionsItem withVisual:[CiStyle toolbarImageForUpdate] withLabel:NSLocalizedString(@"Toolbar_Update_Selected", nil) withAction:@selector(upgradeSelectedFormulae:)];
                break;
                
            default:
                break;
        }
        
        [self validateVisibleItems];
    }
}

- (void)setToolbarItemHomebrewController:(id)controller
{
    NSDictionary *supportedItems = [self customToolbarItemIdentifierToolbarItemLookupDictionary];
    [supportedItems enumerateKeysAndObjectsUsingBlock:^(id key, NSToolbarItem *object, BOOL *stop){
        [object setTarget:controller];
        [object setEnabled:controller != nil]; // Disables the searchbox toolbar item
    }];
}

- (void)setLock:(BOOL)shut
{
    _lock = shut;
    
    self.toolbarItemHomebrewController = shut ? nil : _homebrewViewController;
    [self validateVisibleItems];
}

// NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSDictionary *supportedItems = [self customToolbarItemIdentifierToolbarItemLookupDictionary];
    
	if (![supportedItems objectForKey:itemIdentifier])
	{
		return nil;
	}
    
	return supportedItems[itemIdentifier];
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
	static NSArray *_systemToolbarItemIdentifiers = nil;
    
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

- (NSDictionary *)customToolbarItemIdentifierToolbarItemLookupDictionary
{
	static NSDictionary *_customToolbarItems = nil;
    
	if (!_customToolbarItems)
	{
		_customToolbarItems = @{
            kToolbarItemBrewUpdateToolIdentifier : self.brewUpdateToolToolbarItem,
            kToolbarItemBrewInfoToolIdentifier : self.brewInfoToolToolbarItem,
            kToolbarItemSearchIdentifier : self.searchToolbarItem,
            kToolbarItemMultiActionIdentifier : self.multiActionToolbarItem
        };
	}
    
	return _customToolbarItems;
}

- (NSToolbarItem *)brewUpdateToolToolbarItem
{
	static NSToolbarItem* toolbarItemHomebrewUpdate = nil;
    
	if (!toolbarItemHomebrewUpdate)
	{
        toolbarItemHomebrewUpdate = [self toolbarItemWithIdentifier:kToolbarItemBrewUpdateToolIdentifier 
                                                         withVisual:[CiStyle toolbarImageForUpgrade]
                                                          withLabel:NSLocalizedString(@"Toolbar_Homebrew_Update", nil) 
                                                         withAction:@selector(update:)];
	}
    
	return toolbarItemHomebrewUpdate;
}

- (NSToolbarItem *)brewInfoToolToolbarItem
{
	static NSToolbarItem* toolbarItemInformation = nil;
    
	if (!toolbarItemInformation)
	{
		toolbarItemInformation = [self toolbarItemWithIdentifier:kToolbarItemBrewInfoToolIdentifier 
                                                      withVisual:[CiStyle toolbarImageForMoreInformation]
                                                       withLabel:NSLocalizedString(@"Toolbar_More_Information", nil)
                                                      withAction:@selector(infoForSelectedFormula:)];
	}
    
	return toolbarItemInformation;
}


- (NSToolbarItem *)multiActionToolbarItem
{
	static NSToolbarItem* toolbarItemMultiAction = nil;
    
	if (!toolbarItemMultiAction)
	{
		toolbarItemMultiAction = [self toolbarItemWithIdentifier:kToolbarItemMultiActionIdentifier withVisual:nil withLabel:nil withAction:nil];
	}
    
	return toolbarItemMultiAction;
}

- (NSSearchToolbarItem *)searchToolbarItem
{
	static NSSearchToolbarItem *_searchToolbarItem = nil;
    
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

- (void)modifyToolbarItem:(NSToolbarItem *)item withVisual:(NSImage *)visual withLabel:(NSString *)label withAction:(SEL)action
{
    assert([NSThread isMainThread]);
    
    if (!visual)
    {
        item.view = nil;
    }
    else
    {
        NSButton *button = [NSButton buttonWithImage:visual target:_homebrewViewController action:action];
        
        [button setBezelStyle:NSBezelStyleTexturedRounded];
        [button setButtonType:NSButtonTypeMomentaryPushIn];
        [button setBordered:YES];
        
        [button setAlignment:NSTextAlignmentCenter];
        
        item.view = button;
    }
    
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
