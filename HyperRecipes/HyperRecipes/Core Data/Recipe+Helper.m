//
//  Recipe+Helper.m
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "Recipe+Helper.h"

@implementation Recipe (Helper)

+ (Recipe*)recipeInContext:(NSManagedObjectContext*)context {
    Recipe *recipe = [NSEntityDescription insertNewObjectForEntityForName:@"Recipe" inManagedObjectContext:context];
    
    recipe.difficulty = @(1);
    recipe.favorite = @NO;
    recipe.deleted = @NO;
    recipe.dirty = @NO;
    [recipe touch];

    return recipe;
}

- (void)touch {
    self.dirty = @YES;
    
    // update "updatedAt", too (format: "2014-01-02T15:07:33.378Z")
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    self.updatedAt = [dateFormatter stringFromDate:[NSDate date]];
}

@end
