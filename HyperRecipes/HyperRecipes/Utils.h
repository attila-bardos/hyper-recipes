//
//  Utils.h
//  Chili
//
//  Created by Attila Bárdos on 12/19/13.
//  Copyright (c) 2013 Altair Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecipeDetailsVC.h"

@interface Utils : NSObject

#ifdef DEBUG
#define DLog(...) NSLog(__VA_ARGS__)
#else
#define DLog(...)
#endif

+ (RecipeDetailsVC*)detailsVC;

@end
