//
//  NSDictionary+Json.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSDictionary (BVJSONString)
-(NSString*) getJsonString:(BOOL) prettyPrint;
@end
