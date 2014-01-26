//
//  RecipeListVC.h
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Recipe.h"

@class RecipeListVC;

@protocol RecipleListDelegate <NSObject>
- (void)recipeList:(RecipeListVC*)recipeListVC didSelectRecipe:(Recipe*)recipe;
@end

@interface RecipeListVC : UITableViewController

@property (weak, nonatomic) id<RecipleListDelegate> delegate;

@end
