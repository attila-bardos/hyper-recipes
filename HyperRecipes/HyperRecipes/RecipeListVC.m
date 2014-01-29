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

@interface RecipeListVC () <UISearchBarDelegate>
@property (strong, nonatomic) NSMutableArray *recipes;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UIBarButtonItem *leftBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *rightBarButtonItem;
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
    
    // seacrh bar
    self.searchBar.delegate = self;
    
    // backup left and right bar button items (they will be temporarily removed when searching)
    self.leftBarButtonItem = self.navigationItem.leftBarButtonItem;
    self.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
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
        
        // run a silent sync
        [self performSelectorInBackground:@selector(syncAndReload) withObject:nil];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate recipeList:self didSelectRecipe:[self.recipes objectAtIndex:indexPath.row]];
}

#pragma mark - Search bar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
    
    // "Refresh" and "Add" will be hidden while search is active
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // restore original search and content state
    self.searchBar.showsCancelButton = NO;
    self.searchBar.text = nil;
    [self.searchBar resignFirstResponder];
    [self reloadData];
    
    // restore "Refresh" and "Add" buttons
    self.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.rightBarButtonItem;
}

#pragma mark - Actions

- (IBAction)refreshTapped:(id)sender {
    [self performSelectorInBackground:@selector(syncAndReload) withObject:nil];
}

- (IBAction)addTapped:(id)sender {
    // try to create some yummy recipes if you don't have them yet (this is for demo purposes only, of course)
    Recipe *recipe = [self createSampleContent];
    
    // create a new, empty recipe if we already have both sample recipes
    if (recipe == nil) {
        recipe = [Recipe recipeInContext:[AppDelegate context]];
        recipe.name = @"Untitled recipe";
    }
    
    // save changes
    [AppDelegate saveContext];
    
    // update model
    [self.recipes insertObject:recipe atIndex:0];
    
    // update UI
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.delegate recipeList:self didSelectRecipe:recipe];
    
    // run a silent sync
    [self performSelectorInBackground:@selector(syncAndReload) withObject:nil];
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

    // fetch recipes (either all of them or the ones containing the serach string in their names)
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Recipe"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCompare:)]];
    if (self.searchBar.text.length == 0) {
        request.predicate = [NSPredicate predicateWithFormat:@"deleted == NO"];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"deleted == NO && name CONTAINS[cd] %@", self.searchBar.text];
    }
    self.recipes = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:nil]];
    
    // reload table view (performing on the main thread assures reloadData can be called on a background thread, too)
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    // restore selection if possible
    BOOL selectionRestored = NO;
    if (currentRecipe) {
        NSInteger index = 0;
        for (Recipe *r in self.recipes) {
            if (([r.serverId integerValue] > 0 && [r.serverId isEqualToNumber:currentRecipe.serverId]) || ([r.serverId integerValue] == 0 && [r.name isEqualToString:currentRecipe.name])) {
                [self performSelectorOnMainThread:@selector(selectRowAtIndexPath:) withObject:[NSIndexPath indexPathForRow:index inSection:0] waitUntilDone:NO];
                selectionRestored = YES;
                
                // force an update or the recipe in the details view in case it has changed during a sync
                [self.delegate recipeList:self didSelectRecipe:r];
                
                // quit searching
                break;
            }
            ++index;
        }
    }
    if (!selectionRestored) {
        // this is going to clear the RecipeDetailsVC
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

- (Recipe*)createSampleContent {
    NSManagedObjectContext *context = [AppDelegate context];

    // check if first sample recipe exists and create it if not
    BOOL foundRecipe1 = NO;
    NSString *recipeName1 = @"Steak & guacamole wrap";
    for (Recipe *r in self.recipes) {
        if ([r.name isEqualToString:recipeName1]) {
            foundRecipe1 = YES;
            break;
        }
    }
    if (!foundRecipe1) {
        // http://www.jamieoliver.com/recipes/beef-recipes/steak-and-guacamole-wrap
        Recipe *recipe1 = [Recipe recipeInContext:context];
        recipe1.name = recipeName1;
        recipe1.desc = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sample_1_desc" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        recipe1.instructions = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sample_1_instructions" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        [recipe1 setImage:[UIImage imageNamed:@"sample_1_image.jpg"]];
        return recipe1;
    }
    
    
    // check if first sample recipe exists and create it if not
    BOOL foundRecipe2 = NO;
    NSString *recipeName2 = @"Aussie humble pie";
    for (Recipe *r in self.recipes) {
        if ([r.name isEqualToString:recipeName2]) {
            foundRecipe2 = YES;
            break;
        }
    }
    if (!foundRecipe2) {
        // http://www.jamieoliver.com/recipes/beef-recipes/aussie-humble-pie
        Recipe *recipe2 = [Recipe recipeInContext:context];
        recipe2.name = @"Aussie humble pie";
        recipe2.desc = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sample_2_desc" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        recipe2.instructions = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sample_2_instructions" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        [recipe2 setImage:[UIImage imageNamed:@"sample_2_image.jpg"]];
        return recipe2;
    }
    
    // both samples found, don't create anything new
    return nil;
}

@end
