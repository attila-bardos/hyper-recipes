//
//  Utils.m
//  Chili
//
//  Created by Attila Bárdos on 12/19/13.
//  Copyright (c) 2013 Delta Velorum Kft. All rights reserved.
//

#import "Utils.h"
#import "AppDelegate.h"

@implementation Utils

+ (RecipeDetailsVC*)detailsVC {
    AppDelegate *appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
    UISplitViewController *splitVC = (UISplitViewController*)appDelegate.window.rootViewController;
    UINavigationController *navVC = [splitVC.viewControllers objectAtIndex:1];
    return [navVC.viewControllers firstObject];
}

@end
