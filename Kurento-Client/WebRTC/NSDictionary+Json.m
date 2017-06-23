//
//  NSDictionary+Json.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//
#import "NSDictionary+Json.h"

@implementation NSDictionary (BVJSONString)

- (NSString*)getJsonString:(BOOL) prettyPrint {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    NSData *jsonData1 = [NSJSONSerialization dataWithJSONObject:self
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
@end