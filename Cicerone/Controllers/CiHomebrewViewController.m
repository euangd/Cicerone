//
//	HomebrewController.m
//	Cicerone – The Homebrew GUI App for OS X
//
//	Created by Vincent Saluzzo on 06/12/11.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import "CiFormula.h"
#import "CiFormulaOptionsWindowController.h"
#import "CiFormulaeDataSource.h"
#import "CiSelectedFormulaViewController.h"

#import "CiHomebrewViewController.h"
#import "CiHomebrewManager.h"
#import "CiHomebrewInterface.h"
#import "CiInstallationWindowController.h"
#import "CiUpdateViewController.h"
#import "CiDoctorViewController.h"
#import "CiToolbar.h"
#import "CiAppDelegate.h"
#import "CiStyle.h"
#import "CiLoadingView.h"
#import "CiDisabledView.h"
#import "CiBundleWindowController.h"
#import "CiTask.h"
#import "CiMainWindowController.h"
#import "NSLayoutConstraint+Shims.h"

// HomebrewViewMainContentOption ?
typedef NS_ENUM(NSUInteger, CiHomebrewViewTabViewTabOption) {
    kCiHomebrewViewTabViewTabOptionFormulaeList,
    kCiHomebrewViewTabViewTabOptionDoctorTool,
    kCiHomebrewViewTabViewTabOptionUpdateTool
};

static const CGFloat kPreferedHeightSelectedFormulaView = 120.f;

@interface CiHomebrewViewController () <NSTableViewDelegate, NSToolbarItemValidation,
CiSideBarControllerDelegate,
CiSelectedFormulaViewControllerDelegate,
CiHomebrewManagerDelegate,
CiToolbarProtocol,
NSMenuDelegate,
NSOpenSavePanelDelegate>

@property (weak) CiAppDelegate *appDelegate;

@property NSUInteger lastSelectedSidebarIndex;

@property (readwrite) BOOL searching;
@property (readwrite) BOOL hasUpgrades;
@property (readwrite) BOOL homebrewInstalled;

@property (strong, nonatomic) CiFormulaOptionsWindowController	*formulaOptionsWindowController;
@property (strong, nonatomic) NSWindowController				*operationWindowController;
@property (strong, nonatomic) CiUpdateViewController			*updateViewController;
@property (strong, nonatomic) CiDoctorViewController			*doctorViewController;
@property (strong, nonatomic) CiFormulaPopoverViewController	*formulaPopoverViewController;
@property (strong, nonatomic) CiSelectedFormulaViewController	*selectedFormulaViewController;
@property (strong, nonatomic) CiToolbar							*toolbar;
@property (strong, nonatomic) CiDisabledView					*disabledView;
@property (strong, nonatomic) CiLoadingView						*loadingView;

@property (weak) IBOutlet NSSplitView				*formulaeSplitView;
@property (weak) IBOutlet NSView					*selectedFormulaView;
@property (weak) IBOutlet NSProgressIndicator		*backgroundActivityIndicator;
@property (weak) IBOutlet CiMainWindowController	*mainWindowController;

@property (readonly) CiListMode listMode;

@end

@implementation CiHomebrewViewController
{
    CiHomebrewManager *homebrewManager;
}

- (CiListMode)listMode
{
    return homebrewManager.formulaeDataSource.mode;
}

- (BOOL)isListingPackages
{
    switch (self.listMode) {
        case kCiListModeRepositories:
            return false;
            
        default:
            return true;
    }
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    if ([item.itemIdentifier isEqualToString:kToolbarItemBrewInfoToolIdentifier]) {
        if (self.formulaeTableView.selectedRowIndexes.count > 1) {
            return NO;
        }
    }
    return [self.toolbar validateToolbarItem:item];
}

- (void)actualizeToolbarItem:(NSToolbarItem *)item
{
    // todo: maybe don't even use this to update icons and future popupbutton
    return [self.toolbar actualizeToolbarItem:item];
}

- (CiFormulaPopoverViewController *)formulaPopoverViewController
{
    if (!_formulaPopoverViewController) {
        _formulaPopoverViewController = [[CiFormulaPopoverViewController alloc] init];
        //this will force initialize controller with its view
        __unused NSView *view = _formulaPopoverViewController.view;
    }
    return _formulaPopoverViewController;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _lastSelectedSidebarIndex = -1;
    
    homebrewManager = CiHomebrewManager.sharedManager;
    homebrewManager.delegate = self;
    
    self.selectedFormulaViewController = [[CiSelectedFormulaViewController alloc] init];
    self.selectedFormulaViewController.delegate = self;
    
    self.homebrewInstalled = YES;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveBackgroundActivityNotification:)
                                               name:kDidBeginBackgroundActivityNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didReceiveBackgroundActivityNotification:)
                                               name:kDidEndBackgroundActivityNotification object:nil];
}

- (void)didReceiveBackgroundActivityNotification:(NSNotification*)notification
{
    if ([notification.name isEqualToString:kDidBeginBackgroundActivityNotification])
    {
        [self.backgroundActivityIndicator performSelectorOnMainThread:@selector(startAnimation:)
                                                           withObject:self waitUntilDone:YES];
    }
    else if ([notification.name isEqualToString:kDidEndBackgroundActivityNotification])
    {
        [self.backgroundActivityIndicator performSelectorOnMainThread:@selector(stopAnimation:)
                                                           withObject:self waitUntilDone:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.mainWindowController setUpViews];
    
    self.mainWindowController.windowContentViewHidden = YES;
    
    // this used to initialize formulaeDataSource here, now we just refresh it
    [homebrewManager.formulaeDataSource refreshBackingArray];
    
    self.formulaeTableView.dataSource = homebrewManager.formulaeDataSource;
    self.formulaeTableView.delegate = self;
    self.formulaeTableView.accessibilityLabel = NSLocalizedString(@"Formulae", nil); // @"Casks" ever?
    
    //link formulae tableview
    NSView *formulaeView = self.formulaeSplitView;
    if ([[self.tabView tabViewItems] count] > kCiHomebrewViewTabViewTabOptionFormulaeList) {
        NSTabViewItem *formulaeTab = [self.tabView tabViewItemAtIndex:kCiHomebrewViewTabViewTabOptionFormulaeList];
        [formulaeTab setView:formulaeView];
    }
    
    //Creating view for update tab
    self.updateViewController = [[CiUpdateViewController alloc] initWithNibName:nil bundle:nil];
    self.updateViewController.homebrewViewController = self;
    NSView *updateView = [self.updateViewController view];
    if ([[self.tabView tabViewItems] count] > kCiHomebrewViewTabViewTabOptionUpdateTool) {
        NSTabViewItem *updateTab = [self.tabView tabViewItemAtIndex:kCiHomebrewViewTabViewTabOptionUpdateTool];
        [updateTab setView:updateView];
    }
    
    //Creating view for doctor tab
    self.doctorViewController = [[CiDoctorViewController alloc] initWithNibName:nil bundle:nil];
    self.doctorViewController.homebrewViewController = self;
    NSView *doctorView = [self.doctorViewController view];
    if ([[self.tabView tabViewItems] count] > kCiHomebrewViewTabViewTabOptionDoctorTool) {
        NSTabViewItem *doctorTab = [self.tabView tabViewItemAtIndex:kCiHomebrewViewTabViewTabOptionDoctorTool];
        [doctorTab setView:doctorView];
    }
    
    // todo: investigate; seems pretty dubious
    NSView *selectedFormulaView = [self.selectedFormulaViewController view];
    [self.selectedFormulaView addSubview:selectedFormulaView];
    selectedFormulaView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.selectedFormulaView addConstraints:[NSLayoutConstraint
                                              constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                                              options:0
                                              metrics:nil
                                              views:@{@"view": selectedFormulaView}]];
    
    [self.selectedFormulaView addConstraints:[NSLayoutConstraint
                                              constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                                              options:0
                                              metrics:nil
                                              views:@{@"view": selectedFormulaView}]];
    
    self.sidebarController.delegate = self;
    [self.sidebarController selectSidebarRowWithIndex:kCiSidebarRowInstalledFormulae];
    
    [self addToolbar];
        
    self.loading = YES;
    
    _appDelegate = CiAppDelegateRef;
}

- (void)addToolbar
{
    self.toolbar = [[CiToolbar alloc] initWithIdentifier:@"MainToolbar"];
    self.toolbar.homebrewViewController = self;
    
    self.view.window.toolbar = self.toolbar;
    self.toolbar.displayMode = NSToolbarDisplayModeIconOnly;
}

- (void)addDisabledView
{
    CiDisabledView *disabledView = [[CiDisabledView alloc] initWithFrame:NSZeroRect];
    disabledView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:disabledView];
    
    NSView *referenceView;
    
    referenceView = self.mainWindowController.windowContentView;
    
    [NSLayoutConstraint activate:@[
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual toItem:disabledView
                                     attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual toItem:disabledView
                                     attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual toItem:disabledView
                                     attribute:NSLayoutAttributeTop multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual toItem:disabledView
                                     attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
    ]];
    
    self.disabledView = disabledView;
}

- (void)addLoadingView
{
    CiLoadingView *loadingView = [[CiLoadingView alloc] initWithFrame:NSZeroRect];
    loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:loadingView];
    
    NSView *referenceView = self.mainWindowController.windowContentView;
    
    [NSLayoutConstraint activate:@[
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual toItem:loadingView
                                     attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual toItem:loadingView
                                     attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual toItem:loadingView
                                     attribute:NSLayoutAttributeTop multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:referenceView attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual toItem:loadingView
                                     attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
    ]];
    
    self.loadingView = loadingView;
}

- (void)dealloc
{
    homebrewManager.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateInterfaceItems
{
    NSInteger selectedSidebarRow = self.sidebarController.sidebar.selectedRow;
    
    NSInteger mostRecentlySelectedListIndex = self.formulaeTableView.selectedRow;
    NSIndexSet *allSelectedListIndeces = self.formulaeTableView.selectedRowIndexes;
    
    NSArray *selectedFormulae = [homebrewManager.formulaeDataSource formulaeAtIndexSet:allSelectedListIndeces];
    
    [self.formulaeSplitView setPosition:self.formulaeSplitView.bounds.size.height - kPreferedHeightSelectedFormulaView ofDividerAtIndex:0];
    
    BOOL showFormulaInfo = false; // will get computed based on whether or not the formulae list homebrew view tab view tab option is selected and is not for the repositories sidebar row
    switch (selectedSidebarRow) {
        case kCiSidebarRowRepositories:
            self.toolbar.mode = mostRecentlySelectedListIndex != -1 ? kCiToolbarModeTappedRepository : kCiToolbarModeTap;
            break;
        case kCiSidebarRowDoctor:
        case kCiSidebarRowUpdate:
            self.toolbar.mode = kCiToolbarModeCore;
            break;
        default:
            self.selectedFormulaViewController.formulae = (showFormulaInfo = allSelectedListIndeces.count == 1) ? selectedFormulae : nil;
            
            if (mostRecentlySelectedListIndex != -1) {
                switch ([homebrewManager.formulaeDataSource statusForFormula:[homebrewManager.formulaeDataSource formulaAtIndex:mostRecentlySelectedListIndex]]) {
                    case kCiFormulaStatusInstalled:
                        self.toolbar.mode = kCiToolbarModeInstalledPackage;
                        break;
                        
                    case kCiFormulaStatusOutdated:
                        self.toolbar.mode = kCiToolbarModeOutdatedPackage;
                        break;
                        
                    case kCiFormulaStatusNotInstalled:
                        self.toolbar.mode = kCiToolbarModeNotInstalledPackage;
                        break;
                }
            } else {
                self.toolbar.mode = kCiToolbarModeCore;
            }
            break;
    }
    
    self.selectedFormulaView.hidden = !showFormulaInfo;
    [self.toolbar actualizeVisibleItems];
}

- (void)configureTableForListing:(CiListMode)mode
{
    [self.formulaeTableView deselectAll:nil];
    homebrewManager.formulaeDataSource.mode = mode;
    
    [self clearTransientState];
    
    self.formulaeTableView.mode = mode;
    [self.formulaeTableView reloadData];
    
    [self updateInterfaceItems];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet<NSString *> *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:NSStringFromSelector(@selector(isListingPackages))]) {
        // Add the properties that affect isListingPackages
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[NSStringFromSelector(@selector(listMode)), @"homebrewManager.formulaeDataSource.mode"]];
    }
    
    if ([key isEqualToString:NSStringFromSelector(@selector(listMode))]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"homebrewManager.formulaeDataSource.mode"]];
    }
    
    return keyPaths;
}


#pragma mark – Footer Information Label

- (void)updateInfoLabelWithSidebarSelection
{
    CiSidebarRow selectedSidebarRow = [self.sidebarController.sidebar selectedRow];
    NSString *message = nil;
    
    if (self.isSearching)
    {
        message = NSLocalizedString(@"Sidebar_Info_SearchResults", nil);
    }
    else
    {
        switch (selectedSidebarRow)
        {
            case kCiSidebarRowInstalledFormulae: // Installed Formulae
                message = NSLocalizedString(@"Sidebar_Info_Installed", nil);
                break;
                
            case kCiSidebarRowOutdatedFormulae: // Outdated Formulae
                message = NSLocalizedString(@"Sidebar_Info_Outdated", nil);
                break;
                
            case kCiSidebarRowAllFormulae: // All Formulae
                message = NSLocalizedString(@"Sidebar_Info_All", nil);
                break;
                
            case kCiSidebarRowLeaves:    // Leaves
                message = NSLocalizedString(@"Sidebar_Info_Leaves", nil);
                break;
                
            case kCiSidebarRowRepositories: // Repositories
                message = NSLocalizedString(@"Sidebar_Info_Repos", nil);
                break;
                
            case kCiSidebarRowDoctor: // Doctor
                message = NSLocalizedString(@"Sidebar_Info_Doctor", nil);
                break;
                
            case kCiSidebarRowUpdate: // Update Tool
                message = NSLocalizedString(@"Sidebar_Info_Update", nil);
                break;
                
            case kCiSidebarRowInstalledCasks: // Installed Casks
                message = NSLocalizedString(@"Sidebar_Info_Installed_Casks", nil);
                break;
                
            case kCiSidebarRowOutdatedCasks: // Outdated Casks
                message = NSLocalizedString(@"Sidebar_Info_Outdated_Casks", nil);
                break;
                
            case kCiSidebarRowAllCasks: // All Casks
                message = NSLocalizedString(@"Sidebar_Info_All_Casks", nil);
                break;
                
            default:
                break;
        }
    }
    
    self.informationTextField.stringValue = message;
}

- (void)setLoading:(BOOL)loading
{
    //can stop loading as many times as needed, but should not start multiple times in a row
    if (_loading == loading && loading) {
        return;
    }
    
    _loading = loading;
    
    if (loading) {
        [self addLoadingView];
        
        self.informationTextField.hidden = YES;
        self.mainWindowController.windowContentViewHidden = YES;
        
        self.lock = YES;
    } else {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
        
        if (self.isHomebrewInstalled)
        {
            self.lock = NO;
            
            self.mainWindowController.windowContentViewHidden = NO;
            self.informationTextField.hidden = NO;
            
            // Used after unlocking the app when inserting custom homebrew installation path
            BOOL shouldReselectFirstRow = _lastSelectedSidebarIndex == -1;
            
            [self.sidebarController selectSidebarRowWithIndex:shouldReselectFirstRow ? kCiSidebarRowInstalledFormulae : (NSUInteger)_lastSelectedSidebarIndex];
        }
    }
}

// intentionally allows lock to happen multiple times
- (void)setLock:(BOOL)load
{
    _lock = load;
    
    if (load) {
        self.sidebarController.loading = YES;
        
        self.toolbar.mode = kCiToolbarModeDud;
    } else {
        [self clearTransientState];
        
        [homebrewManager.formulaeDataSource refreshBackingArray];
        
        self.sidebarController.loading = NO;
        
        self.hasUpgrades = ([[CiHomebrewManager sharedManager] outdatedFormulae].count > 0);
    }
    
}

- (void)clearTransientState
{
    [[self.formulaeTableView menu] cancelTracking];
    
    //        self.selectedFormula = nil;
    self.selectedFormulaViewController.formulae = nil;
}

#pragma mark - Homebrew Manager Delegate

- (void)homebrewManagerWillLoadHomebrewPrefixState:(CiHomebrewManager *)manager
{
    // set the content view to a loading screen and lock the UI only if the current content view is unrelated to the
//    if (!hasOperationPopup) {
//    }
    self.loading = YES;
}

- (void)homebrewManagerDidLoadHomebrewPrefixState:(CiHomebrewManager *)manager
{
    self.loading = NO;
}

- (void)homebrewManager:(CiHomebrewManager *)manager didFinishSearchReturningSearchResults:(NSArray *)searchResults
{
    [self loadSearchResults];
}

- (void)homebrewManager:(CiHomebrewManager *)manager didNotFindBrew:(BOOL)didNot
{
    self.homebrewInstalled = !didNot;
    
    if (didNot)
    {
        [self addDisabledView];
        self.informationTextField.hidden = YES;
        self.mainWindowController.windowContentViewHidden = YES;
        self.lock = false;
        self.toolbar.mode = kCiToolbarModeDud;
        self.sidebarController.sidebar.enabled = NO;
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"Generic_Error", nil);
        [alert addButtonWithTitle:NSLocalizedString(@"Message_No_Homebrew_Title", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
        alert.informativeText = NSLocalizedString(@"Message_No_Homebrew_Body", nil);
        alert.window.title = NSLocalizedString(@"Cicerone", nil);
        
        NSURL *brew_URL = [NSURL URLWithString:@"http://brew.sh"];
        
        if ([alert respondsToSelector:@selector(beginSheetModalForWindow:completionHandler:)]) {
            [alert beginSheetModalForWindow:_appDelegate.window completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertFirstButtonReturn) {
                    [[NSWorkspace sharedWorkspace] openURL:brew_URL];
                }
            }];
        } else {
            NSModalResponse returnCode = [alert runModal];
            if (returnCode == NSAlertFirstButtonReturn) {
                [[NSWorkspace sharedWorkspace] openURL:brew_URL];
            }
        }
    }
    else
    {
        [self.disabledView removeFromSuperview];
        self.disabledView = nil;
        self.informationTextField.hidden = NO;
        self.mainWindowController.windowContentViewHidden = NO;
        
        self.lock = YES;
        
        [[CiHomebrewManager sharedManager] loadHomebrewPrefixState];
    }
}

- (void)showFormulaInfoForCurrentlySelectedFormulaUsingInfoType:(CiFormulaInfoType)type
{
    NSPopover *popover = self.formulaPopoverViewController.formulaPopover;
    if ([popover isShown])
    {
        [popover close];
    }
    
    NSInteger selectedIndex = [self.formulaeTableView selectedRow];
    CiFormula *formula = [self selectedFormula];
    
    if (!formula)
    {
        return;
    }
    
    self.formulaPopoverViewController.infoType = type;
    self.formulaPopoverViewController.formula = formula;
    
    NSRect anchorRect = [self.formulaeTableView rectOfRow:selectedIndex];
    anchorRect.origin = [self.scrollView_formulae convertPoint:anchorRect.origin fromView:self.formulaeTableView];
    
    [popover showRelativeToRect:anchorRect ofView:self.scrollView_formulae preferredEdge:NSMaxXEdge];
}

- (void)toggleSidebar:(id)sender
{
    [self.mainWindowController.splitViewController toggleSidebar:sender];
}

#pragma mark - Search Mode

- (void)loadSearchResults
{
    [self clearTransientState];
    [self.sidebarController deselectAllSidebarRows];
    self.searching = YES;
    [self configureTableForListing:kCiListModeSearchFormulae];
}

- (void)endSearchAndCleanup
{
    self.toolbar.searchField.stringValue = @"";
    [self clearTransientState];
    [self.sidebarController selectSidebarRowWithIndex:kCiSidebarRowInstalledFormulae];
    self.searching = NO;
    [self configureTableForListing:kCiListModeInstalledFormulae];
    [self updateInfoLabelWithSidebarSelection];
}

#pragma mark - NSTableView Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self updateInterfaceItems];
}

#pragma mark - CiSelectedFormulaViewController Delegate

- (void)selectedFormulaViewDidUpdateFormulaInfoForFormula:(CiFormula *)formula
{
    // Change the value here without using the setter
    //    if (formula) {
    //        [self willChangeValueForKey:NSStringFromSelector(@selector(selectedFormula))];
    //        _selectedFormula = formula;
    //        [self didChangeValueForKey:NSStringFromSelector(@selector(selectedFormula))];
    //    }
}

#pragma mark - CiSideBarDelegate Delegate

- (void)sourceListSelectionDidChange
{
    CiHomebrewViewTabViewTabOption tabOption;
    NSInteger selectedSidebarRow = [self.sidebarController.sidebar selectedRow];
    
    if ([self isSearching])
    {
        [self endSearchAndCleanup];
    }
    
    if (selectedSidebarRow >= 0)
    {
        _lastSelectedSidebarIndex = selectedSidebarRow;
    }
    
    [self.formulaeTableView deselectAll:nil];
    //    [self setSelectedFormula:nil];
    
    [self updateInterfaceItems];
    
    switch (selectedSidebarRow) {
        case kCiSidebarRowDoctor: // Doctor
            tabOption = kCiHomebrewViewTabViewTabOptionDoctorTool;
            goto apply;
            
        case kCiSidebarRowUpdate: // Update Tool
            tabOption = kCiHomebrewViewTabViewTabOptionUpdateTool;
            goto apply;
            
        case kCiSidebarRowInstalledFormulae: // Installed Formulae
            [self configureTableForListing:kCiListModeInstalledFormulae];
            break;
            
        case kCiSidebarRowOutdatedFormulae: // Outdated Formulae
            [self configureTableForListing:kCiListModeOutdatedFormulae];
            break;
            
        case kCiSidebarRowAllFormulae: // All Formulae
            [self configureTableForListing:kCiListModeAllFormulae];
            break;
            
        case kCiSidebarRowLeaves:    // Leaves
            [self configureTableForListing:kCiListModeLeaves];
            break;
            
        case kCiSidebarRowRepositories: // Repositories
            [self configureTableForListing:kCiListModeRepositories];
            break;
            
        case kCiSidebarRowInstalledCasks: // Installed Casks
            [self configureTableForListing:kCiListModeInstalledCasks];
            break;
            
        case kCiSidebarRowOutdatedCasks: // Outdated Casks
            [self configureTableForListing:kCiListModeOutdatedCasks];
            break;
            
        case kCiSidebarRowAllCasks: // All Casks
            [self configureTableForListing:kCiListModeAllCasks];
            break;
    }
    
    tabOption = kCiHomebrewViewTabViewTabOptionFormulaeList;
    
apply:
    [self updateInfoLabelWithSidebarSelection];
    [self.tabView selectTabViewItemAtIndex:tabOption];
}

#pragma mark - NSMenu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    [self.formulaeTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.formulaeTableView clickedRow]] byExtendingSelection:NO];
}

#pragma mark - IBActions

- (IBAction)showFormulaInfo:(id)sender
{
    [self showFormulaInfoForCurrentlySelectedFormulaUsingInfoType:kCiFormulaInfoTypeGeneral];
}

- (IBAction)showFormulaDependents:(id)sender
{
    BOOL onlyInstalledFormulae = YES;
    
    if ([sender isKindOfClass:[NSMenuItem class]])
    {
        onlyInstalledFormulae = [sender isAlternate];
    }
    
    [self showFormulaInfoForCurrentlySelectedFormulaUsingInfoType:onlyInstalledFormulae ? kCiFormulaInfoTypeInstalledDependents : kCiFormulaInfoTypeAllDependents];
}

- (IBAction)installSelectedFormula:(id)sender
{
    [self checkForBackgroundTask];
    
    CiFormula *formula = [self selectedFormula];
    if (!formula)
    {
        return;
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Generic_Attention", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Confirmation_Install_Formula", nil), formula.name];
    
    alert.window.title = NSLocalizedString(@"Cicerone", nil);
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationInstall formulae:@[formula] options:nil];
    }
}

- (IBAction)installFormulaWithOptions:(id)sender
{
    [self checkForBackgroundTask];
    
    CiFormula *formula = [self selectedFormula];
    if (!formula)
    {
        return;
    }
    
    self.formulaOptionsWindowController = [CiFormulaOptionsWindowController runFormula:formula withCompletionBlock:^(NSArray *options) {
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationInstall formulae:@[formula] options:options];
    }];
}

- (IBAction)uninstallSelectedFormula:(id)sender
{
    [self checkForBackgroundTask];
    
    CiFormula *formula = [self selectedFormula];
    if (!formula)
    {
        return;
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Generic_Attention", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Confirmation_Uninstall_Formula", nil), formula.name];
    alert.window.title = NSLocalizedString(@"Cicerone", nil);
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationUninstall formulae:@[formula] options:nil];
    }
}

- (IBAction)upgradeSelectedFormulae:(id)sender
{
    [self checkForBackgroundTask];
    
    NSArray *selectedFormulae = [self selectedFormulae];
    if (![selectedFormulae count])
    {
        return;
    }
    
    NSString *formulaNames = [[self selectedFormulaNames] componentsJoinedByString:@", "];
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Message_Update_Formulae_Title", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Message_Update_Formulae_Body", nil), formulaNames];
    alert.window.title = NSLocalizedString(@"Cicerone", nil);
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationUpgrade formulae:selectedFormulae options:nil];
    }
}


- (IBAction)upgradeAllOutdatedFormulae:(id)sender
{
    [self checkForBackgroundTask];
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Message_Update_All_Outdated_Title", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
    alert.informativeText = NSLocalizedString(@"Message_Update_All_Outdated_Body", nil);
    alert.window.title = NSLocalizedString(@"Cicerone", nil);
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationUpgrade formulae:nil options:nil];
    }
}

- (IBAction)tap:(id)sender
{
    [self checkForBackgroundTask];
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Message_Tap_Title", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_OK", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
    alert.informativeText = NSLocalizedString(@"Message_Tap_Body", nil);
    alert.window.title = NSLocalizedString(@"Cicerone", nil);
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,24)];
    alert.accessoryView = input;
    
    NSInteger returnValue = [alert runModal];
    if (returnValue == NSAlertFirstButtonReturn)
    {
        NSString* name = [input stringValue];
        
        if ([name length] <= 0)
        {
            return;
        }
        
        CiFormula *lformula = [CiFormula formulaWithName:name cask:NO];
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationTap formulae:@[lformula] options:nil];
    }
}

- (IBAction)removeSelectedListing:(id)sender
{
    switch (self.listMode) {
        case kCiListModeRepositories:
            return [self untapSelectedRepository:sender];

        default:
            return [self uninstallSelectedFormula:sender];
    }
}

- (IBAction)untapSelectedRepository:(id)sender
{
    [self checkForBackgroundTask];
    CiFormula *formula = [self selectedFormula];
    
    if (!formula)
    {
        return;
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Message_Untap_Title", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_OK", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Generic_Cancel", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Message_Untap_Body", nil), formula.name]];
    [alert.window setTitle:NSLocalizedString(@"Cicerone", nil)];
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationUntap formulae:@[formula] options:nil];
    }
}

- (IBAction)openSelectedFormulaWebsite:(id)sender
{
    CiFormula *formula = [self selectedFormula];
    
    if (!formula)
    {
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:formula.website];
}

- (void)performSearchWithString:(NSString *)searchPhrase
{
    if ([searchPhrase isEqualToString:@""])
    {
        [self endSearchAndCleanup];
    }
    else
    {
        [[CiHomebrewManager sharedManager] updateSearchWithName:searchPhrase];
    }
}

- (void)infoForSelectedFormula:(id)sender { 
    [self showFormulaInfo:sender];
}

- (void)update:(id)sender {
    [self.sidebarController selectSidebarRowWithIndex:kCiSidebarRowUpdate];
    [self.updateViewController runStopUpdate:nil];
}

- (IBAction)beginFormulaSearch:(id)sender
{
    [self.toolbar showSearch];
}

- (IBAction)runHomebrewCleanup:(id)sender
{
    self.operationWindowController = [CiInstallationWindowController runWithOperation:kCiWindowOperationCleanup formulae:nil options:nil];
}

- (IBAction)runHomebrewExport:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.nameFieldLabel = @"Export To:";
    savePanel.prompt = @"Export";
    savePanel.nameFieldStringValue = @"Brewfile";
    
    [savePanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
        NSURL *fileURL = [savePanel URL];
        
        if (fileURL && result)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.operationWindowController = [CiBundleWindowController runExportOperationWithFile:fileURL];
            });
        }
    }];
}

- (IBAction)runHomebrewImport:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.nameFieldLabel = @"Import From:";
    openPanel.prompt = @"Import";
    openPanel.nameFieldStringValue = @"Brewfile";
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.delegate = self;
    
    [openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
        NSURL *fileURL = [openPanel URL];
        
        if (fileURL && result)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.operationWindowController = [CiBundleWindowController runImportOperationWithFile:fileURL];
            });
        }
    }];
}

- (void)checkForBackgroundTask
{
    if (_appDelegate.isRunningBackgroundTask)
    {
        [_appDelegate displayBackgroundWarning];
        return;
    }
}

- (CiFormula *)selectedFormula
{
    return [[homebrewManager formulaeDataSource] formulaAtIndex:[self.formulaeTableView selectedRow]];
}

- (NSArray *)selectedFormulae
{
    return [homebrewManager.formulaeDataSource formulaeAtIndexSet:[self.formulaeTableView selectedRowIndexes]];
}

- (NSArray *)selectedFormulaNames
{
    return [[self selectedFormulae] valueForKeyPath:@"@unionOfObjects.name"];
}

#pragma mark - Open Save Panels Delegate

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
    return [[[url pathComponents] lastObject] isEqualToString:@"Brewfile"];
}

@end
