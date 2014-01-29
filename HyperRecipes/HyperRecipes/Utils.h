//
//  Utils.h
//  HyperRecipes
//
//  Created by Attila Bárdos on 01/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecipeDetailsVC.h"

@interface Utils : NSObject

#ifdef DEBUG
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...)
#endif

@end
