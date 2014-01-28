//
//  Recipe+Helper.h
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "Recipe.h"

@interface Recipe (Helper)

+ (Recipe*)recipeInContext:(NSManagedObjectContext*)context;

- (void)touch;
- (UIImage*)image;
- (void)setImage:(UIImage*)image;
- (NSData*)imageData;
- (void)removeImage;

@end
