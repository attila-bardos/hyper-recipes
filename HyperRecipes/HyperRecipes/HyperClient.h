//
//  HyperClient.h
//  HyperRecipes
//
//  Created by Attila Bárdos on 1/25/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HyperClient : NSObject

+ (HyperClient*)sharedInstance;

- (void)sync;
- (void)syncWithCompletionHandler:(void (^)(NSError *error))completion;

@end
