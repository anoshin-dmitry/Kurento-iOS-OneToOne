//
//  ViewController.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraContainerView;
@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet CameraContainerView *viewRemoteContainer;
@property (weak, nonatomic) IBOutlet CameraContainerView *viewLocalContainer;

@end

