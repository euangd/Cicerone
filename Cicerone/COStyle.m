//
//  COStyle.h
//  Bruh
//
//  Created by Marek Hrusovsky on 25/08/15.
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

#import "COStyle.h"

@implementation COStyle

+ (NSFont *)defaultFixedWidthFont
{
	static NSFont *font = nil;
	
	if (!font)
	{
		font = [NSFont fontWithName:@"Andale Mono" size:12];
        
		if (!font)
        {
            font = [NSFont fontWithName:@"Menlo" size:12];
        }
        
		if (!font)
        {
            font = [NSFont systemFontOfSize:12];
        }
	}
	
	return font;
}

#pragma mark Toolbar

+ (NSToolbarSizeMode)toolbarSize
{
    return NSToolbarSizeModeSmall;
}

+ (NSImage *)toolbarImageForInstall
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"arrow.down.to.line.compact" accessibilityDescription:@"download"];
	}
	
	return image;
}

+ (NSImage *)toolbarImageForUninstall
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"trash.fill" accessibilityDescription:@"delete"];
	}
	
	return image;
}

+ (NSImage *)toolbarImageForTap
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"plus.rectangle.on.folder" accessibilityDescription:@"download"];
	}
	
	return image;
}

+ (NSImage *)toolbarImageForUntap
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"minus" accessibilityDescription:@"delete"];
	}
	
	return image;
}

+ (NSImage *)toolbarImageForUpdate
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"arrow.circlepath" accessibilityDescription:@"upgrade"];
	}
	
	return image;
}

+ (NSImage *)toolbarImageForMoreInformation
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"doc.plaintext" accessibilityDescription:@"info text"];
	}
	
	return image;
}

+ (NSImage *)toolbarImageForUpgrade
{
	static NSImage *image;
    
	if (!image)
    {
		image = [NSImage imageWithSystemSymbolName:@"arrow.triangle.capsulepath" accessibilityDescription:@"refresh"];
	}
	
	return image;
}

#pragma mark Popover

+ (NSColor *)popoverTitleColor
{
	static NSColor *color;
    
	if (!color)
    {
        color = [NSColor textColor];
	}
	
	return color;
}

+ (NSColor *)popoverTextViewColor
{
	static NSColor *color;
    
	if (!color)
    {
        color = [NSColor textColor];
	}
	
	return color;
}

#pragma mark Sidebar

+ (NSColor *)sidebarDividerColor
{
	static NSColor *color;
    
	if (!color)
    {
		color = [NSColor colorWithCalibratedRed:0.835294 green:0.858824 blue:0.858824 alpha:1.0];
	}
	
	return color;
}

+ (NSImage *)installedSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"checkmark.square"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_Installed", nil)];
}

+ (NSImage *)outdatedSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"clock.arrow.circlepath"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_Outdated", nil)];
}

+ (NSImage *)allFormulaeSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"books.vertical"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_All", nil)];
}

+ (NSImage *)leavesSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"leaf"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_Leaves", nil)];
}

+ (NSImage *)repositoriesSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"building.columns"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_Repos", nil)];
}

+ (NSImage *)doctorSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"stethoscope"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_Doctor", nil)];
}

+ (NSImage *)updateSidebarIconImage
{
    return [NSImage imageWithSystemSymbolName:@"arrow.triangle.2.circlepath.circle"
                     accessibilityDescription:NSLocalizedString(@"Sidebar_Item_Update", nil)];
}

@end
