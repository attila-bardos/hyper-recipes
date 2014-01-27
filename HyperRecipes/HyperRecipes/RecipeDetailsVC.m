//
//  RecipeDetailsVC.m
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "RecipeDetailsVC.h"
#import "Recipe+Helper.h"
#import "AppDelegate.h"
#import "Utils.h"

@interface RecipeDetailsVC ()

@end

@implementation RecipeDetailsVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recipeDidChange:) name:@"RecipeDidChange" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)touchTapped:(id)sender {
    // touch the recipe
    [self.recipe touch];
    self.recipe.name = self.recipe.updatedAt;
    [AppDelegate saveContext];
    
    // send a notification so UI could be updated to show changed data
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeDidChange" object:self.recipe];
}

#pragma mark - Recipe list delegate

- (void)recipeList:(RecipeListVC *)recipeListVC didSelectRecipe:(Recipe *)recipe {
    self.recipe = recipe;
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    if (recipe) {
        DLog(@"recipe: %@, difficulty = %@, updatedAt = %@", recipe.name, recipe.difficulty, recipe.updatedAt);
    }
}

#pragma mark - Notifications

- (void)recipeDidChange:(NSNotification*)notification {
    if (self.recipe == (Recipe*)notification.object) {
        [self reloadData];
    }
}

#pragma mark - Other methods

- (void)reloadData {
    self.navigationItem.title = (self.recipe ? self.recipe.name : @"Recipe details");
}

@end
