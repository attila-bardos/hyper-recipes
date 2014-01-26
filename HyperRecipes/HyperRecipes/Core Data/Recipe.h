//
//  Recipe.h
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Recipe : NSManagedObject

@property (nonatomic, retain) NSNumber * serverId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * difficulty;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * instructions;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSString * imageUrl;
@property (nonatomic, retain) NSString * updatedAt;
@property (nonatomic, retain) NSNumber * dirty;
@property (nonatomic, retain) NSNumber * deleted;
@property (nonatomic, retain) NSString * imageFileName;

@end
