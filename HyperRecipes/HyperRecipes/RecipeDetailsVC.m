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

@interface RecipeDetailsVC () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UITextView *descTextView;
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UITextView *instructionsTextView;
@property (strong, nonatomic) UIBarButtonItem *doneButton;
@property (strong, nonatomic) UIBarButtonItem *addToFavoritesButton;
@property (strong, nonatomic) UIBarButtonItem *removeFromFavoritesButton;
@property (strong, nonatomic) UITextView *currentTextView;
@property (strong, nonatomic) UIActionSheet *imageSourceActionSheet;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIPopoverController *imagePickerPopover;
@end

#pragma mark - Constants

static const CGFloat TextViewHeight = 238.0;

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
    
    // bar buttons
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    self.addToFavoritesButton = [[UIBarButtonItem alloc] initWithTitle:@"Add to Favorites" style:UIBarButtonItemStylePlain target:self action:@selector(addToFavoritesTapped:)];
    self.removeFromFavoritesButton = [[UIBarButtonItem alloc] initWithTitle:@"Remove from Favorites" style:UIBarButtonItemStylePlain target:self action:@selector(removeFromFavoritesTapped:)];
    
    // image picker
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)imageTapped:(id)sender {
    UIButton *button = (UIButton*)sender;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // present an action sheet so the user can pick the source if multiple source types are available
        if (self.imageSourceActionSheet == nil) {
            self.imageSourceActionSheet = [[UIActionSheet alloc] initWithTitle:@"Pick image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Camera", nil];
        }
        [self.imageSourceActionSheet showFromRect:button.bounds inView:button animated:YES];
    } else {
        // present the "Photo library" picker if camera isn't available (read: running in simulator)
        if ([self.imagePickerPopover isPopoverVisible] == NO) {
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
            [self.imagePickerPopover presentPopoverFromRect:button.bounds inView:button permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        }
    }
}

- (void)doneTapped:(id)sender {
    [self.currentTextView resignFirstResponder];
}

- (void)addToFavoritesTapped:(id)sender {
    // update model
    self.recipe.favorite = @YES;
    [self.recipe touch];
    [AppDelegate saveContext];
    
    // let others know about the change
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeDidChange" object:self.recipe];
}

- (void)removeFromFavoritesTapped:(id)sender {
    // update model
    self.recipe.favorite = @NO;
    [self.recipe touch];
    [AppDelegate saveContext];
    
    // let others know about the change
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeDidChange" object:self.recipe];
}

#pragma mark - Recipe list delegate

- (void)recipeList:(RecipeListVC *)recipeListVC didSelectRecipe:(Recipe *)recipe {
    self.recipe = recipe;
    [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

#pragma mark - Text view delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // adjust the text view
    if (textView == self.descTextView) {
        // remove placeholder text and reset color (if needed)
        if (self.recipe.desc.length == 0) {
            textView.text = nil;
            textView.textColor = [UIColor lightGrayColor];
        }

        // animate to the right position
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect f = self.descTextView.frame;
            self.descTextView.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width, TextViewHeight);
            self.instructionsLabel.alpha = 0.0;
            self.instructionsTextView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.instructionsLabel.hidden = YES;
            self.instructionsTextView.hidden = YES;
        }];
    } else if (textView == self.instructionsTextView) {
        // remove placeholder text and reset color (if needed)
        if (self.recipe.instructions.length == 0) {
            textView.text = nil;
            textView.textColor = [UIColor lightGrayColor];
        }
        
        // animate to the right position
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect f = self.descTextView.frame;
            self.instructionsLabel.frame = self.descLabel.frame;
            self.instructionsTextView.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width, TextViewHeight);
            self.descLabel.alpha = 0.0;
            self.descTextView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.descLabel.hidden = YES;
            self.descTextView.hidden = YES;
        }];
    }
    
    // add "Done" button
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    // store the text view to resgining from first responder state when done
    self.currentTextView = textView;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    // adjust text view positions and visibility
    if (textView == self.descTextView) {
        self.instructionsLabel.hidden = NO;
        self.instructionsTextView.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutTextViewsWithTextViewBeingEdited:nil];
            self.instructionsLabel.alpha = 1.0;
            self.instructionsTextView.alpha = 1.0;
        } completion:^(BOOL finished) {
            ;
        }];
    } else if (textView == self.instructionsTextView) {
        self.descLabel.hidden = NO;
        self.descTextView.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutTextViewsWithTextViewBeingEdited:nil];
            self.descLabel.alpha = 1.0;
            self.descTextView.alpha = 1.0;
        } completion:^(BOOL finished) {
            ;
        }];
    }
    
    // update model
    if (textView == self.descTextView) {
        self.recipe.desc = textView.text;
    } else if (textView == self.instructionsTextView) {
        self.recipe.instructions = textView.text;
    }
    [self.recipe touch];
    [AppDelegate saveContext];

    // remove "Done" button
    self.navigationItem.rightBarButtonItem = nil;
    
    // reset
    self.currentTextView = nil;
    
    // let others know about the change (which will cause a reload, too)
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeDidChange" object:self.recipe];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // make sure the user can't enter text longer than the server's known limit
    NSString *updatedText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return (updatedText.length < 255);
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Camera"]) {
        // camera needs to be displayed full screen
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePicker animated:YES completion:nil];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Photo Library"]) {
        // if self.imagePicker was permenently assigned to self.imagePickerPopover, then trying to present it modally (camera; see above) would cause an exception
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
        [self.imagePickerPopover presentPopoverFromRect:self.imageButton.bounds inView:self.imageButton permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // udpate model
    self.recipe.name = textField.text;
    [self.recipe touch];
    [AppDelegate saveContext];
    
    // let others know about the change
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeDidChange" object:self.recipe];
    
    // a nice little easter egg :)
    if ([textField.text isEqualToString:@"dragons and unicorns"]) {
        [self performSelectorInBackground:@selector(haveSomeFun) withObject:nil];
    }
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // overwrite the current local image with the selected one
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (image == nil) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    [self.recipe setImage:image];
    [self.recipe touch];
    [AppDelegate saveContext];
    
    // dismiss the popover or the modal
    if ([self.imagePickerPopover isPopoverVisible]) {
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    // update the UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecipeDidChange" object:self.recipe];
}

#pragma mark - Notifications

- (void)recipeDidChange:(NSNotification*)notification {
    Recipe *recipe = (Recipe*)notification.object;
    if (self.recipe == recipe) {
        [self reloadData];
    }
}

#pragma mark - Other methods

- (void)reloadData {
    if (self.recipe) {
        // name
        self.nameTextField.text = self.recipe.name;
        
        // image (local image has a precenedence over the remote image because after changing it [but before sync has completed] the local one is the newer one)
        if (self.recipe.imageFileName.length > 0) {
            [self.imageView setImage:self.recipe.image];
        } else if (self.recipe.imageUrl.length > 0) {
            [self.imageView setImageWithURL:[NSURL URLWithString:self.recipe.imageUrl] placeholderImage:[UIImage imageNamed:@"image_placeholder.png"]];
        } else {
            [self.imageView setImage:nil];
        }
        
        // description
        if (self.recipe.desc.length > 0) {
            self.descTextView.text = self.recipe.desc;
            self.descTextView.textColor = [UIColor lightGrayColor];
        } else {
            self.descTextView.text = @"Add description";
            self.descTextView.textColor = ((AppDelegate*)[UIApplication sharedApplication].delegate).window.tintColor;      // global tint color (make look like a button)
        }
        
        // instructions
        if (self.recipe.instructions.length > 0) {
            self.instructionsTextView.text = self.recipe.instructions;
            self.instructionsTextView.textColor = [UIColor lightGrayColor];
        } else {
            self.instructionsTextView.text = @"Add instructions";
            self.instructionsTextView.textColor = ((AppDelegate*)[UIApplication sharedApplication].delegate).window.tintColor;      // global tint color (make look like a button)
        }
        
        // adjust text views' height and position according to their content
        [self layoutTextViewsWithTextViewBeingEdited:nil];
        
        // set favorite button
        self.navigationItem.leftBarButtonItem = ([self.recipe.favorite boolValue] ? self.removeFromFavoritesButton : self.addToFavoritesButton);

        // show all views (unhide)
        self.imageButton.hidden = NO;
        self.nameTextField.hidden = NO;
        self.imageView.hidden = NO;
        self.descLabel.hidden = NO;
        self.descTextView.hidden = NO;
        self.instructionsLabel.hidden = NO;
        self.instructionsTextView.hidden = NO;
    } else {
        // hide all views (make it an empty view)
        self.imageButton.hidden = YES;
        self.nameTextField.hidden = YES;
        self.imageView.hidden = YES;
        self.descLabel.hidden = YES;
        self.descTextView.hidden = YES;
        self.instructionsLabel.hidden = YES;
        self.instructionsTextView.hidden = YES;
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)layoutTextViewsWithTextViewBeingEdited:(UITextView*)textView {
    // description text view
    CGFloat y = self.descTextView.frame.origin.y;
    CGFloat height = (textView == self.descTextView ? TextViewHeight : [self textViewHeightForAttributedText:self.descTextView.attributedText andWidth:self.descTextView.bounds.size.width]);
    CGRect f = self.descTextView.frame;
    self.descTextView.frame = CGRectMake(f.origin.x, y, f.size.width, height);
    y += self.descTextView.frame.size.height + 25;
    
    // instructions label
    f = self.instructionsLabel.frame;
    self.instructionsLabel.frame = CGRectMake(f.origin.x, y, f.size.width, f.size.height);
    y += f.size.height + 10;
    
    // instructiosn text view
    f = self.instructionsTextView.frame;
    height = (textView == self.instructionsTextView ? TextViewHeight : [self textViewHeightForAttributedText:self.instructionsTextView.attributedText andWidth:self.instructionsTextView.bounds.size.width]);
    self.instructionsTextView.frame = CGRectMake(f.origin.x, y, f.size.width, height);
}

// http://stackoverflow.com/questions/19028743/ios7-uitextview-contentsize-height-alternative
- (CGFloat)textViewHeightForAttributedText:(NSAttributedString *)text andWidth:(CGFloat)width {
    UITextView *textView = [[UITextView alloc] init];
    [textView setAttributedText:text];
    CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}

- (void)haveSomeFun {
    NSString *message = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.velorum.hu/downloads/easter_egg.txt"] encoding:NSUTF8StringEncoding error:nil];
    if (message.length > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Congratulations" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"I can't wait", nil];
        [alert show];
    }
}

@end
