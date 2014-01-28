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
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface RecipeDetailsVC () <UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *favoritesButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UITextView *descTextView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UITextView *instructionsTextView;
@property (strong, nonatomic) UIBarButtonItem *doneButton;
@property (strong, nonatomic) UITextView *currentTextView;
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
    
    // delegates
    self.nameTextField.delegate = self;
    self.descTextView.delegate = self;
    self.instructionsTextView.delegate = self;
    
    // "Done" button for the text views
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (void)doneTapped:(id)sender {
    [self.currentTextView resignFirstResponder];
}

#pragma mark - Recipe list delegate

- (void)recipeList:(RecipeListVC *)recipeListVC didSelectRecipe:(Recipe *)recipe {
    self.recipe = recipe;
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    if (recipe) {
        DLog(@"recipe: %@", recipe);
    }
}

#pragma mark - Text view delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // adjust text view height
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutTextViewsWithTextViewBeingEdited:textView];
    } completion:^(BOOL finished) {
        ;
    }];
    
    // add "Done" button
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    // store the text view to resgining from first responder when done
    self.currentTextView = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    // adjust text view height
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutTextViewsWithTextViewBeingEdited:nil];
    } completion:^(BOOL finished) {
        ;
    }];

    // remove "Done" button
    self.navigationItem.rightBarButtonItem = nil;
    
    // reset
    self.currentTextView = nil;
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.recipe.name = textField.text;
    [self.recipe touch];
    [AppDelegate saveContext];
}

#pragma mark - Notifications

- (void)recipeDidChange:(NSNotification*)notification {
    if (self.recipe == (Recipe*)notification.object) {
        [self reloadData];
    }
}

#pragma mark - Other methods

- (void)reloadData {
    if (self.recipe) {
        // load values
        self.nameTextField.text = self.recipe.name;
        if (self.recipe.imageUrl.length > 0) {
            [self.imageView setImageWithURL:[NSURL URLWithString:self.recipe.imageUrl]];
        } else if (self.recipe.imageFileName.length > 0) {
            [self.imageView setImage:self.recipe.image];
        }
        self.descTextView.text = self.recipe.desc;
        self.instructionsTextView.text = self.recipe.instructions;

        // adjust visibility
        self.favoritesButton.hidden = NO;
        self.nameTextField.hidden = NO;
        self.imageView.hidden = NO;
        self.descLabel.hidden = NO;
        self.descTextView.hidden = NO;
        self.instructionsLabel.hidden = NO;
        self.instructionsTextView.hidden = NO;
        
        // adjust text views' height and position according to their content
        [self layoutTextViewsWithTextViewBeingEdited:nil];
    } else {
        // adjust visibility
        self.favoritesButton.hidden = YES;
        self.nameTextField.hidden = YES;
        self.imageView.hidden = YES;
        self.descLabel.hidden = YES;
        self.descTextView.hidden = YES;
        self.instructionsLabel.hidden = YES;
        self.instructionsTextView.hidden = YES;
    }
}

- (void)layoutTextViewsWithTextViewBeingEdited:(UITextView*)textView {
    // description text view
    CGFloat y = self.descTextView.frame.origin.y;
    CGFloat height = (textView == self.descTextView ? 150.0 : [self textViewHeightForAttributedText:self.descTextView.attributedText andWidth:self.descTextView.bounds.size.width]);
    CGRect f = self.descTextView.frame;
    self.descTextView.frame = CGRectMake(f.origin.x, y, f.size.width, height);
    y += self.descTextView.frame.size.height + 25;
    
    // instructions label
    f = self.instructionsLabel.frame;
    self.instructionsLabel.frame = CGRectMake(f.origin.x, y, f.size.width, f.size.height);
    y += f.size.height + 10;
    
    // instructiosn text view
    f = self.instructionsTextView.frame;
    height = (textView == self.instructionsTextView ? 150.0 : [self textViewHeightForAttributedText:self.instructionsTextView.attributedText andWidth:self.instructionsTextView.bounds.size.width]);
    self.instructionsTextView.frame = CGRectMake(f.origin.x, y, f.size.width, height);
}

// http://stackoverflow.com/questions/19028743/ios7-uitextview-contentsize-height-alternative
- (CGFloat)textViewHeightForAttributedText:(NSAttributedString *)text andWidth:(CGFloat)width {
    UITextView *textView = [[UITextView alloc] init];
    [textView setAttributedText:text];
    CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}

@end
