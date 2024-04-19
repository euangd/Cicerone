//
//  BPToolbar.h
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

#import <Cocoa/Cocoa.h>

@protocol BPToolbarProtocol <NSObject>

@required
- (void)performSearchWithString:(NSString *)search;
- (void)updateHomebrew:(id)sender;
- (void)upgradeSelectedFormulae:(id)sender;
- (void)showFormulaInfo:(id)sender;
- (void)tapRepository:(id)sender;
- (void)untapRepository:(id)sender;
- (void)installFormula:(id)sender;
- (void)uninstallFormula:(id)sender;
@end

@interface BPToolbar : NSToolbar <NSToolbarDelegate>

// user access intent, as in the intent the user would have to access bar controls with the current context

typedef NS_ENUM(NSUInteger, CiOBarUserAccessIntent)
{
	CiOBarUAINone,
    
	CiOBarUAIBase,
    
	CiOBarUAIActOnInstallable,
	CiOBarUAIActOnInstalled,
    
	CiOBarUAIActOnOldVersionInstalled,
	CiOBarUAIActOnOldVersionsInstalled,
    
	CiOBarUAIActOnSourcesViewerVisible,
	CiOBarUAIActOnInstalledSource
};

@property (nonatomic, weak) id activeVisualContext;

- (void)setItemsOnIntent:(CiOBarUserAccessIntent)intent;
- (void)freeze:(BOOL)shouldFreeze;
- (void)startSearchEventCatch;
- (NSSearchField*)searchField;

@end
