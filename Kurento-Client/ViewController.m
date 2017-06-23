//
//  ViewController.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import "ViewController.h"
#import <KurentoToolbox/KurentoToolbox.h>
#import "WebRTCClient.h"
#import <AVFoundation/AVFoundation.h>

#import "RTCVideoTrack.h"
#import "RTCEAGLVideoView.h"

#import "CameraContainerView.h"

@interface ViewController () <RTCDelegate> {
    UITapGestureRecognizer *tapGestureRecognizer;
}

@property (nonatomic, strong) UIView* localVideoView;
@property (nonatomic, strong) UIView* remoteVideoView;

@end

@implementation ViewController  {
    WebRTCClient *rtcClient;
}

@synthesize nameField;

- (void)viewDidLoad {
    [super viewDidLoad];
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    [self.nameField becomeFirstResponder];
  
    rtcClient = [[WebRTCClient alloc] init];
    rtcClient.delegate = self;
    
    NSURL *wsURI = [NSURL URLWithString:@"https://lcconnect.xyz:8443/call"];
    //NSURL *wsURI = [NSURL URLWithString:@"https://192.168.1.170:8443/call"];
    [rtcClient initClient:wsURI];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)registerAction:(id)sender {
    [self onTap];
    NSString *name = nameField.text;
    [rtcClient registerUser:@"194282" UserId:@"2868" Name:name];
}

- (IBAction)cancelPressed:(id)sender {
    [rtcClient rejectCall:@"closed"];
}

- (void)onCallReceived:(NSString *)from {
    [self onTap];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Call"
                                                                   message:@"Do you accept call?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [rtcClient acceptCall];
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [rtcClient rejectCall:@"user rejected"];
                                                          }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onStartCommunication:(UIView *)videoView {
    
}

- (void)onStopCommunication {
    
}

- (void)onTap {
    NSLog(@"view tapped.");
    [self.nameField endEditing: YES];
}

- (void)onAddLocalStream:(UIView *)videoView {
    if (self.localVideoView != nil) {
        [self.localVideoView removeFromSuperview];
    }
    self.localVideoView = videoView;
    [self.viewLocalContainer addSubview:self.localVideoView];
}

- (void)onAddRemoteStream:(UIView *)videoView {
    if (self.remoteVideoView != nil) {
        [self.remoteVideoView removeFromSuperview];
    }
    self.remoteVideoView = videoView;
    [self.viewRemoteContainer addSubview:self.remoteVideoView];
}

- (void)onRemoveRemoteStream {
    if (self.remoteVideoView != nil) {
        [self.remoteVideoView removeFromSuperview];
    }
    self.remoteVideoView = nil;
}

- (void)viewDidLayoutSubviews {
    if (self.localVideoView) {
        self.localVideoView.frame = self.viewLocalContainer.bounds;
    }
    if (self.remoteVideoView) {
        self.remoteVideoView.frame = self.viewRemoteContainer.bounds;
    }
}

// delegate methods(for testing: directly shows the local stream on view load)
/*
- (void)didGetLocalTrack: (RTCVideoTrack*)videoTrack {
    if (self.localVideoTrack) {
        [self.localVideoTrack removeRenderer:self.localView];
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];
    }
    self.localVideoTrack = videoTrack;
    [self.localVideoTrack addRenderer:self.localView];
}*/
@end
