//
//  Recipe.m
//  HyperRecipes
//
//  Created by Attila Bárdos on 1/25/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "Recipe.h"

@implementation Recipe

- (NSString*)description {
    return [NSString stringWithFormat:@"%d (%@; %@)", self.serverId, self.name, self.updatedAt];
}

@end
