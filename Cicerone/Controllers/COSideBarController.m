//
//  COSideBarController.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COSideBarController.h"
#import "COSourceListTableCellView.h"
#import "COHomebrewManager.h"
#import "COStyle.h"

@interface COSideBarController ()

@property (strong, nonatomic) PXSourceListItem *rootSidebarCategory;

@property (strong, nonatomic) PXSourceListItem *instaledFormulaeSidebarItem;
@property (strong, nonatomic) PXSourceListItem *outdatedFormulaeSidebarItem;
@property (strong, nonatomic) PXSourceListItem *allFormulaeSidebarItem;
@property (strong, nonatomic) PXSourceListItem *leavesFormulaeSidebarItem;
@property (strong, nonatomic) PXSourceListItem *repositoriesFormulaeSidebarItem;

@property (strong, nonatomic) PXSourceListItem *instaledCasksSidebarItem;
@property (strong, nonatomic) PXSourceListItem *outdatedCasksSidebarItem;
@property (strong, nonatomic) PXSourceListItem *allCasksSidebarItem;

@end

@implementation COSideBarController

- (instancetype)init
{
	self = [super init];
	
    if (self) {
        PXSourceListItem *parent;
        _rootSidebarCategory = [PXSourceListItem itemWithTitle:@"" identifier:@"root"];
        
        
        parent = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Group_Formulae", nil) identifier:@"group"];
        [_rootSidebarCategory addChildItem:parent];
        
        _instaledFormulaeSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Installed", nil) identifier:@"item"];
        _instaledFormulaeSidebarItem.icon = [COStyle installedSidebarIconImage];
        [parent addChildItem:_instaledFormulaeSidebarItem];
        
        _outdatedFormulaeSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Outdated", nil) identifier:@"item"];
        _outdatedFormulaeSidebarItem.icon = [COStyle outdatedSidebarIconImage];
        [parent addChildItem:_outdatedFormulaeSidebarItem];
        
        _allFormulaeSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_All", nil) identifier:@"item"];
        _allFormulaeSidebarItem.icon = [COStyle allFormulaeSidebarIconImage];
        [parent addChildItem:_allFormulaeSidebarItem];
        
        _leavesFormulaeSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Leaves", nil) identifier:@"item"];
        _leavesFormulaeSidebarItem.icon = [COStyle leavesSidebarIconImage];
        [parent addChildItem:_leavesFormulaeSidebarItem];
        
        
        parent = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Group_Casks", nil) identifier:@"group"];
        [_rootSidebarCategory addChildItem:parent];
        
        _instaledCasksSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Installed_Casks", nil) identifier:@"item"];
        _instaledCasksSidebarItem.icon = [COStyle installedSidebarIconImage];
        [parent addChildItem:_instaledCasksSidebarItem];
        
        _outdatedCasksSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Outdated_Casks", nil) identifier:@"item"];
        _outdatedCasksSidebarItem.icon = [COStyle outdatedSidebarIconImage];
        [parent addChildItem:_outdatedCasksSidebarItem];
        
        _allCasksSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_All_Casks", nil) identifier:@"item"];
        _allCasksSidebarItem.icon = [COStyle allFormulaeSidebarIconImage];
        [parent addChildItem:_allCasksSidebarItem];
        
        
        parent = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Group_Tools", nil) identifier:@"group"];
        [_rootSidebarCategory addChildItem:parent];
        
        PXSourceListItem *item;
        
        item = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Doctor", nil) identifier:@"item"];
        item.badgeValue = nil;
        item.icon = [COStyle doctorSidebarIconImage];
        [parent addChildItem:item];
        
        item = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Update", nil) identifier:@"item"];
        item.badgeValue = nil;
        item.icon = [COStyle updateSidebarIconImage];
        [parent addChildItem:item];
        
        _repositoriesFormulaeSidebarItem = [PXSourceListItem itemWithTitle:NSLocalizedString(@"Sidebar_Item_Repos", nil) identifier:@"item"];
        _repositoriesFormulaeSidebarItem.icon = [COStyle repositoriesSidebarIconImage];
        [parent addChildItem:_repositoriesFormulaeSidebarItem];
        
        
        self.sidebar.accessibilityLabel = NSLocalizedString(@"Sidebar_VoiceOver_Tools", nil);
	}
	
    return self;
}

- (void)setLoading:(BOOL)loading
{
//    if (_loading != loading) {
//    }
    self.sidebar.enabled = !(_loading = loading);
    
    self.instaledFormulaeSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] installedFormulae] count]);
    self.outdatedFormulaeSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] outdatedFormulae] count]);
    self.allFormulaeSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] allFormulae] count]);
    self.leavesFormulaeSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] leavesFormulae] count]);
    self.repositoriesFormulaeSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] repositoriesFormulae] count]);
    
    self.instaledCasksSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] installedCasks] count]);
    self.outdatedCasksSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] outdatedCasks] count]);
    self.allCasksSidebarItem.badgeValue = @(loading ? -1 : [[[COHomebrewManager sharedManager] allCasks] count]);
    
    [self.sidebar reloadData];
}

#pragma mark - PXSourceList Data Source

- (NSUInteger)sourceList:(PXSourceList *)sourceList numberOfChildrenOfItem:(PXSourceListItem *)item
{
	if (!item) { //Is root
		return [[self.rootSidebarCategory children] count];
	} else {
		return [[item children] count];
	}
}

- (id)sourceList:(PXSourceList *)sourceList child:(NSUInteger)index ofItem:(PXSourceListItem *)item
{
	if (!item) {
		return [[self.rootSidebarCategory children] objectAtIndex:index];
	} else {
		return [[item children] objectAtIndex:index];
	}
}

- (BOOL)sourceList:(PXSourceList *)sourceList isItemExpandable:(PXSourceListItem *)item
{
	if (!item) {
		return YES;
	} else {
		return [item hasChildren];
	}
}

- (__kindof PXSourceListTableCellView *)updateSourceListTableCellView:(__kindof PXSourceListTableCellView *)cellView withSourceListItem:(PXSourceListItem *)item
{
    cellView.textField.stringValue = item.title;
    cellView.imageView.image = item.icon;
    return cellView;
}

#pragma mark - PXSourceList Delegate

- (BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group
{
	return YES;
}

- (NSView *)sourceList:(PXSourceList *)sourceList viewForItem:(PXSourceListItem *)sourceListItem
{
    if (![[sourceListItem identifier] isEqualToString:@"item"]) {
        return [self updateSourceListTableCellView:[sourceList makeViewWithIdentifier:@"HeaderCell" owner:nil] withSourceListItem:sourceListItem];
    }
    
    if (sourceListItem.badgeValue) {
        if (sourceListItem.badgeValue.integerValue < 0) {
            COSourceListTableCellView *cellView = [self updateSourceListTableCellView:[sourceList makeViewWithIdentifier:@"LoadingCell" owner:nil] withSourceListItem:sourceListItem];
            cellView.loading = YES;
            
            return cellView;
        } else {
            PXSourceListTableCellView *cellView = [self updateSourceListTableCellView:[sourceList makeViewWithIdentifier:@"MainCell" owner:nil] withSourceListItem:sourceListItem];
            cellView.badgeView.badgeValue = (NSUInteger)sourceListItem.badgeValue.integerValue;
            cellView.badgeView.hidden = NO;
            
            [cellView.badgeView calcSize];
            
            return cellView;
        }
    } else {
        return [self updateSourceListTableCellView:[sourceList makeViewWithIdentifier:@"ToolCell" owner:nil] withSourceListItem:sourceListItem];
    }
}

- (void)sourceListSelectionDidChange:(NSNotification *)notification
{
	if ([self.delegate respondsToSelector:@selector(sourceListSelectionDidChange)]) {
		[self.delegate sourceListSelectionDidChange];
	}
}

#pragma mark - Actions

- (void)deselectAllSidebarRows
{
    if (!_loading) {
        [self.sidebar deselectAll:self];
    }
}

- (void)selectSidebarRowWithIndex:(NSUInteger)index
{
    if (!_loading) {
        [self.sidebar selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    }
}

- (IBAction)selectSidebarRowWithSenderTag:(id)sender
{
	[self selectSidebarRowWithIndex:[sender tag]];
}

@end
