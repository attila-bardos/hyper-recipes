//
//  HyperClient.m
//  HyperRecipes
//
//  Created by Attila Bárdos on 1/25/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "HyperClient.h"
#import <AFNetworking.h>
#import "Utils.h"
#import "Recipe.h"

@interface HyperClient ()
@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;
@end

@implementation HyperClient

+ (HyperClient*)sharedInstance {
    static HyperClient *sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[HyperClient alloc] init];
        sharedInstance.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://hyper-recipes.herokuapp.com"]];
    }
    return sharedInstance;
}

- (void)downloadRecipesWithCompletionHandler:(void (^)(NSArray *recipes, NSError *error))completion {
    [self.manager GET:@"/recipes" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DLog(@"%@ response:\n%@", operation.request.URL, responseObject);
        
        // process response
        if (completion) {
            // make sure that response is an array
            if ([responseObject isKindOfClass:[NSArray class]] == NO) {
                NSError *error = [NSError errorWithDomain:@"HyperRecipes" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"response is not an array (%@)", operation.request.URL]}];
                DLog(@"** error: %@", [error localizedDescription]);
                if (completion) {
                    completion(nil, error);
                }
            }
            
            // process the array
            NSMutableArray *recipes = [NSMutableArray array];
            for (NSDictionary *r in responseObject) {
                // make sure it's a dictionary
                if ([r isKindOfClass:[NSDictionary class]] == NO) {
                    DLog(@"** error: array elem is not a dictionary");
                    continue;
                }
                
                // create a new recipe
                Recipe *recipe = [[Recipe alloc] init];
                recipe.serverId = [r[@"id"] integerValue];
                recipe.name = r[@"name"];
                recipe.difficulty = [r[@"difficulty"] integerValue];
                recipe.desc = r[@"description"];
                recipe.instructions = r[@"instructions"];
                recipe.favorite = [r[@"favorite"] boolValue];
                NSString *photoUrlString = r[@"photo"][@"url"];
                recipe.imageURL = (photoUrlString.length > 0 ? [NSURL URLWithString:photoUrlString] : nil);
                recipe.updatedAt = r[@"updated_at"];
                [recipes addObject:recipe];
            }

            // return result
            if (completion) {
                completion(recipes, nil);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"** error: %@ (%@)", [error localizedDescription], operation.request.URL);
        if (completion) {
            completion(nil, error);
        }
    }];
}

@end
