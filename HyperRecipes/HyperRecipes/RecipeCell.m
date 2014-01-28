//
//  RecipeCell.m
//  HyperRecipes
//
//  Created by Attila Bárdos on 1/28/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "RecipeCell.h"

@implementation RecipeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
