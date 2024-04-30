//
//  CiSideBarController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

@import PXSourceList;
@import Foundation;

typedef NS_ENUM(NSUInteger, CiSidebarRow)
{
	kCiSidebarRowFormulaeHeader,
	kCiSidebarRowInstalledFormulae,
	kCiSidebarRowOutdatedFormulae,
	kCiSidebarRowAllFormulae,
	kCiSidebarRowLeaves,
	
	kCiSidebarRowCasksHeader,
	kCiSidebarRowInstalledCasks,
	kCiSidebarRowOutdatedCasks,
	kCiSidebarRowAllCasks,
	
	kCiSidebarRowToolsHeader,
	kCiSidebarRowRepositories,
	kCiSidebarRowDoctor,
	kCiSidebarRowUpdate,
	
};

@protocol CiSideBarControllerDelegate <NSObject>
- (void)sourceListSelectionDidChange;
@end

@interface CiSideBarController : NSObject <PXSourceListDataSource, PXSourceListDelegate>

@property (assign) IBOutlet PXSourceList *sidebar;

@property (weak) id <CiSideBarControllerDelegate>delegate;

- (void)refreshSidebarBadges;
- (void)configureSidebarSettings;

- (IBAction)selectSideBarRowWithSenderTag:(id)sender;

@end
