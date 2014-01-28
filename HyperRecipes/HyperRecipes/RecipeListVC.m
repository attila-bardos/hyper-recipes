//
//  RecipeListVC.m
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "RecipeListVC.h"
#import "Recipe+Helper.h"
#import "AppDelegate.h"
#import "Utils.h"
#import "RecipeDetailsVC.h"
#import "HyperClient.h"
#import "RecipeCell.h"

@interface RecipeListVC ()
@property (strong, nonatomic) NSMutableArray *recipes;
@end

@implementation RecipeListVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

- (void)viewDidAppear:(BOOL)animated {
    [self performSelectorInBackground:@selector(syncAndReload) withObject:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recipes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"RecipeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    // configure the cell
    Recipe *recipe = [self.recipes objectAtIndex:indexPath.row];
    ((RecipeCell*)cell).nameLabel.text = recipe.name;
    ((RecipeCell*)cell).favoriteImageView.hidden = ([recipe.favorite boolValue] == NO);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // update model
        Recipe *recipe = [self.recipes objectAtIndex:indexPath.row];
        recipe.deleted = @YES;
        [AppDelegate saveContext];
        [self.recipes removeObjectAtIndex:indexPath.row];

        // update UI
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.delegate recipeList:self didSelectRecipe:nil];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate recipeList:self didSelectRecipe:[self.recipes objectAtIndex:indexPath.row]];
}

#pragma mark - Actions

- (IBAction)refreshTapped:(id)sender {
    [self performSelectorInBackground:@selector(syncAndReload) withObject:nil];
}

- (IBAction)addTapped:(id)sender {
#if 0
    // create a new recipe
    Recipe *recipe = [Recipe recipeInContext:[AppDelegate context]];
    recipe.name = [[NSDate date] description];
    [AppDelegate saveContext];
#endif

    // http://www.jamieoliver.com/recipes/beef-recipes/steak-and-guacamole-wrap
    Recipe *recipe = [Recipe recipeInContext:[AppDelegate context]];
    recipe.name = @"Aussie humble pie";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample_2_desc" ofType:@"txt"];
    DLog(@"path = %@", path);
    recipe.desc = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sample_2_desc" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    recipe.instructions = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sample_2_instructions" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    UIImage *image = [UIImage imageNamed:@"sample_2_image.jpg"];
    [recipe setImage:image];
    [AppDelegate saveContext];

    // update model
    [self.recipes insertObject:recipe atIndex:0];
    
    // update UI
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.delegate recipeList:self didSelectRecipe:recipe];
}

#pragma mark - Notifications

- (void)recipeDidChange:(NSNotification*)notification {
    // look for recipe and reload its row in the table view
    Recipe *recipe = (Recipe*)notification.object;
    NSInteger index = 0;
    for (Recipe *r in self.recipes) {
        if (r == recipe) {
            [self performSelectorOnMainThread:@selector(reloadAndSelectRowAtIndexPath:) withObject:[NSIndexPath indexPathForRow:index inSection:0] waitUntilDone:NO];
            break;
        }
        ++index;
    }
}

#pragma mark - Other methods

- (void)syncAndReload {
    [[HyperClient sharedInstance] syncWithCompletionHandler:^(NSError *error) {
        if (!error) {
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Synchronization failed" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)reloadData {
    // store currently selected recipe so we could possibe restore the selection after reload
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    Recipe *currentRecipe = (indexPath ? [self.recipes objectAtIndex:indexPath.row] : nil);

    // fetch recipes
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"deleted = %@", @NO];
    self.recipes = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:nil]];
    
    // reload table view (performing on the main thread assures this method can be called on a
    // background thread, too)
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    // restore selection if possible
    BOOL selectionRestored = NO;
    if (currentRecipe) {
        NSInteger index = 0;
        for (Recipe *r in self.recipes) {
            if (([r.serverId integerValue] > 0 && [r.serverId isEqualToNumber:currentRecipe.serverId]) || [r.name isEqualToString:currentRecipe.name]) {
                [self performSelectorOnMainThread:@selector(selectRowAtIndexPath:) withObject:[NSIndexPath indexPathForRow:index inSection:0] waitUntilDone:NO];
                selectionRestored = YES;
                break;
            }
            ++index;
        }
    }
    if (!selectionRestored) {
        // update details VC if selection has changed
        [self.delegate recipeList:self didSelectRecipe:nil];
    }
}

- (void)selectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)reloadAndSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end
