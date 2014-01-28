//
//  Recipe+Helper.m
//  HyperRecipes
//
//  Created by Attila Bardos on 1/26/14.
//  Copyright (c) 2014 Delta Velorum Kft. All rights reserved.
//

#import "Recipe+Helper.h"
#import "Utils.h"

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

- (UIImage*)image {
    UIImage *image = nil;

    NSString *path = [self imagePath];
    if (path) {
        image = [UIImage imageWithContentsOfFile:path];
    }
    
    return image;
}

- (void)setImage:(UIImage*)image {
    // generate a UUID (will be used as file name)
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    self.imageFileName = (__bridge NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject);
    
    // save the image into a JPEG file in the Cache folder with a UUID name and store the UUID in the fileName attribute
    NSData *data = UIImageJPEGRepresentation(image, 0.9);
    NSString *path = [self imagePath];
    if ([data writeToFile:path atomically:YES] == NO) {
        DLog(@"** error: can't save image to %@", path);
        self.imageFileName = nil;
    }
}

- (NSData*)imageData {
    NSData *data = nil;
    
    NSString *path = [self imagePath];
    if (path) {
        data = [NSData dataWithContentsOfFile:path];
    }
    
    return data;
}

- (NSString*)imagePath {
    NSString *path = nil;
    
    if (self.imageFileName) {
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        path = [NSString stringWithFormat:@"%@/%@", cachePath, self.imageFileName];
    }
    
    return path;
}

- (void)removeImage {
    NSString *path = [self imagePath];
    if (path) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!error) {
            self.imageFileName = nil;
        } else {
            DLog(@"** error: %@ (when removing local image file: %@)", [error localizedDescription], path);
        }
    }
}

@end
