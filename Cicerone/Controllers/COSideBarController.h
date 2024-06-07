//
//  COSideBarController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 05/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

@import PXSourceList;
@import Foundation;

typedef NS_ENUM(NSUInteger, COSidebarRow)
{
	kCOSidebarRowFormulaeHeader,
	kCOSidebarRowInstalledFormulae,
	kCOSidebarRowOutdatedFormulae,
	kCOSidebarRowAllFormulae,
	kCOSidebarRowLeaves,
    
	kCOSidebarRowCasksHeader,
	kCOSidebarRowInstalledCasks,
	kCOSidebarRowOutdatedCasks,
	kCOSidebarRowAllCasks,
    
	kCOSidebarRowManagementHeader,
    kCOSidebarRowDoctor,
    kCOSidebarRowUpdate,
    kCOSidebarRowRepositories,
	
};

@protocol COSideBarControllerDelegate <NSObject>
- (void)sourceListSelectionDidChange;
@end

@interface COSideBarController : NSObject <PXSourceListDataSource, PXSourceListDelegate>

@property (assign) IBOutlet PXSourceList *sidebar;

@property (weak) id <COSideBarControllerDelegate>delegate;

@property (nonatomic, getter=isLoading) BOOL loading;

- (IBAction)selectSidebarRowWithSenderTag:(id)sender;
- (void)deselectAllSidebarRows;
- (void)selectSidebarRowWithIndex:(NSUInteger)index;

@end
