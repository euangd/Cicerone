//
//  CiToolbar.h
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

@protocol CiToolbarProtocol <NSObject>

@required
- (void)performSearchWithString:(NSString *)search;

- (void)update:(id)sender;
- (void)upgradeSelectedFormulae:(id)sender;
- (void)infoForSelectedFormula:(id)sender;
- (void)tap:(id)sender;
- (void)untapSelectedRepository:(id)sender;
- (void)installSelectedFormula:(id)sender;
- (void)uninstallSelectedFormula:(id)sender;
@end

@interface CiToolbar : NSToolbar <NSToolbarDelegate, NSToolbarItemValidation>

// bar use mode, as in the mode which affects how the bar would be used

typedef NS_ENUM(NSUInteger, CiToolbarMode)
{
	kCiToolbarModeDud,
    
	kCiToolbarModeCore,
    
	kCiToolbarModeNotInstalledPackage,
	kCiToolbarModeInstalledPackage,
    
	kCiToolbarModeOutdatedPackage,
    
	kCiToolbarModeTap,
	kCiToolbarModeTappedRepository
};

@property (nonatomic) CiToolbarMode mode;

@property (nonatomic, weak) id homebrewViewController;

- (void)showSearch;
- (NSSearchField*)searchField;

@end
