//
//  Recipe.h
//  HyperRecipes
//
//  Created by Attila Bárdos on 1/25/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Recipe : NSObject

@property NSInteger serverId;
@property (strong, nonatomic) NSString *name;
@property NSInteger difficulty;
@property (strong, nonatomic) NSString *desc;
@property (strong, nonatomic) NSString *instructions;
@property BOOL favorite;
@property NSURL *imageURL;
@property UIImage *image;
@property (strong, nonatomic) NSString *updatedAt;

@end
