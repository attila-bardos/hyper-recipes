//
//  RecipeCell.h
//  HyperRecipes
//
//  Created by Attila Bárdos on 1/28/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecipeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteImageView;

@end
