//
//  WebRTCClient.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KurentoToolbox/KurentoToolbox.h>
#import <SocketRocket/SRWebSocket.h>
#import "NSDictionary+Json.h"
#import "RTCPeer.h"
@protocol RTCDelegate

- (void)onCallReceived:(NSString *)from;
- (void)onStartCommunication:(UIView *)videoView;
- (void)onStopCommunication;
- (void)onAddLocalStream:(UIView *)videoView;
- (void)onAddRemoteStream:(UIView *)videoView;
- (void)onRemoveRemoteStream;

@end

// for test
/*@protocol TestDelegate
- (void)didGetLocalTrack: (RTCVideoTrack*)videoTrack;
@end*/

@interface WebRTCClient : NSObject <SRWebSocketDelegate, NBMRendererDelegate>

- (void)initClient:(NSURL *)wsURI;
- (void)registerUser:(NSString *)claimId UserId:(NSString *)userId Name:(NSString *)name;
- (void)rejectCall:(NSString *)reason;
- (void)acceptCall;
- (void)sendMessage:(NSString *)message;
- (void)didAddRemoteStream: (RTCMediaStream*)remoteStream;
- (void)didRemoveRemoteStream;
//- (void)startLocalMedia; //for test

@property (nonatomic, retain) id <RTCDelegate> delegate;
@property (nonatomic, strong) RTCPeer *rtcPeer;
@property (nonatomic, strong) id<NBMRenderer> localRenderer;
@property (nonatomic, strong) id<NBMRenderer> remoteRenderer;
@property (nonatomic, strong) RTCMediaStream *localStream;
@property (nonatomic, strong) RTCMediaStream *remoteStream;

@property (nonatomic, assign) NSTimeInterval openChannelTimeout;
@property (nonatomic, assign) NSTimeInterval keepAliveInterval;
//@property (nonatomic, strong) id<TestDelegate> testDelegate;

@end