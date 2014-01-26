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
}

- (void)viewDidAppear:(BOOL)animated {
    [self performSelectorInBackground:@selector(reloadData) withObject:nil];
}

- (void)didReceiveMemoryWarning
{
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
    cell.textLabel.text = recipe.name;
    DLog(@"name = %@, serverId = %d, updatedAt = %@", recipe.name, [recipe.serverId integerValue], recipe.updatedAt);
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // update model
        Recipe *recipe = [self.recipes objectAtIndex:indexPath.row];
        recipe.deleted = @YES;
        [((AppDelegate*)[UIApplication sharedApplication].delegate) saveContext];
        [self.recipes removeObjectAtIndex:indexPath.row];

        // update UI
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.delegate recipeList:self didSelectRecipe:nil];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate recipeList:self didSelectRecipe:[self.recipes objectAtIndex:indexPath.row]];
}

#pragma mark - Actions

- (IBAction)refreshTapped:(id)sender {
    [self performSelectorInBackground:@selector(syncAndReload) withObject:nil];
}

- (IBAction)addTapped:(id)sender {
    // create a new recipe
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    Recipe *recipe = [NSEntityDescription insertNewObjectForEntityForName:@"Recipe" inManagedObjectContext:context];
    recipe.name = [[NSDate date] description];
    recipe.deleted = @NO;
    [recipe touch];
    [context save:nil];
    
    // update model
    [self.recipes insertObject:recipe atIndex:0];
    
    // update UI
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.delegate recipeList:self didSelectRecipe:recipe];
}

#pragma mark - Other methods

- (void)syncAndReload {
    [[HyperClient sharedInstance] syncWithCompletionHandler:^(NSError *error) {
        if (!error) {
            [self reloadData];
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
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
    request.predicate = [NSPredicate predicateWithFormat:@"deleted = %@", @NO];
    self.recipes = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:nil]];
    
    // reload table view
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    // restore selection if possible
    if (currentRecipe) {
        NSInteger index = 0;
        for (Recipe *r in self.recipes) {
            if (([r.serverId integerValue] > 0 && [r.serverId isEqualToNumber:currentRecipe.serverId]) || [r.name isEqualToString:currentRecipe.name]) {
                [self performSelectorOnMainThread:@selector(selectRowAtIndexPath:) withObject:[NSIndexPath indexPathForRow:index inSection:0] waitUntilDone:NO];
                break;
            }
            ++index;
        }
    }
}

- (void)selectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end
