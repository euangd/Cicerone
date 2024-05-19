//
//  NSString+URLValidation.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 05/05/14.
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

#import "NSURL+URLValidation.h"

@implementation NSURL (URLValidation)

+ (NSURL *)validatedURLWithString:(NSString *)urlString {
    // Check for nil or empty string
    if (urlString == nil || [urlString length] == 0) {
        return nil;
    }
    
    // Attempt to create a URL
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Check if the URL is valid
    if (url && url.scheme && url.host) {
        return url;
    } else {
        return nil;
    }
}

@end
