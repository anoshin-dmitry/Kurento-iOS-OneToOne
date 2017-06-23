//
//  CameraContainerView.m
//  Kurento-Client
//
//  Created by Tomasson on 11/23/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import "CameraContainerView.h"

@implementation CameraContainerView

- (void) layoutSubviews {
    if (self.subviews != nil) {
        for (UIView *subview in self.subviews) {
            subview.frame = self.bounds;
        }
    }
}

@end
