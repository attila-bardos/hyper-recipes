//
//  RecipeDetailsVC.h
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Recipe.h"
#import "RecipeListVC.h"

@interface RecipeDetailsVC : UIViewController <RecipleListDelegate>

@property (strong, nonatomic) Recipe *recipe;

- (void)reloadData;

@end
