//
//	COFormula.h
//	Bruh – The Homebrew GUI App for OS X 
//
//	Created by Bruno Philipe on 4/3/14.
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

#import <Foundation/Foundation.h>
#import "COFormulaOption.h"

extern NSString *const kCOFormulaDidUpdateNotification;

@protocol COFormulaDataProvider <NSObject>
@required
- (NSString *)informationWithFormulaName:(NSString *)name cask:(BOOL)isCask;
@end

@interface COFormula : NSObject <NSSecureCoding, NSCopying>

@property (copy, readonly) NSString *name;
@property (copy, readonly) NSString *version;
@property (copy, readonly) NSString *latestVersion;
@property (copy, readonly) NSString *shortLatestVersion;
@property (copy, readonly) NSString *information;
@property (copy, readonly) NSString *installPath;
@property (copy, readonly) NSString *dependencies;
@property (copy, readonly) NSString *conflicts;
@property (copy, readonly) NSString *shortDescription;
@property (strong, readonly) NSURL *website;
@property (strong, readonly) NSArray *options;
@property (getter=isCask, readonly) BOOL cask;

/**
 *  @return `YES` if the formula is installed, or `NO` otherwise.
 */
@property (getter=isInstalled, readonly) BOOL installed;

/**
 *  @return `YES` if the formula is installed and outdated, or `NO` otherwise.
 */
@property (getter=isOutdated, readonly) BOOL outdated;

/**
 *  The short name for the formula. Useful for taps. Returns the remaining substring after the last slash character.
 *
 *  @return The last substring after the last slash character.
 */
@property (readonly) NSString *installedName;

@property BOOL needsInformation;

+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version withLatestVersion:(NSString*)latestVersion cask:(BOOL)isCask;
+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version cask:(BOOL)isCask;
+ (instancetype)formulaWithName:(NSString*)name cask:(BOOL)isCask;

@end
