//
//  WebRTCClient.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <libjingle_peerconnection/RTCICECandidate.h>
#import <libjingle_peerconnection/RTCMediaStream.h>
#import "WebRTCClient.h"

#import "RTCPeerConnectionFactory.h"
#import "RTCVideoCapturer.h"
#import "RTCMediaConstraints.h"
#import <AVFoundation/AVFoundation.h>

#define CALLSTATE_NO_CALL 0
#define CALLSTATE_POST_CALL 1
#define CALLSTATE_DISABLED 2
#define CALLSTATE_IN_CALL 3
static NSTimeInterval kChannelTimeoutInterval = 5.0;
static NSTimeInterval kChannelKeepaliveInterval = 20.0;

typedef NS_ENUM(NSInteger, TransportChannelState) {
    // State when connecting.
    TransportChannelStateOpening,
    // State when connection is established and ready for use.
    TransportChannelStateOpen,
    // State when disconnecting.
    TransportChannelStateClosing,
    // State when disconnected.
    TransportChannelStateClosed
};

@interface WebRTCClient() {
    
}
@property (nonatomic, strong) RTCPeerConnectionFactory *factory;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, readwrite) TransportChannelState channelState;
@property (nonatomic, strong) NSTimer *keepAliveTimer;
@end

@implementation WebRTCClient {
    NBMJSONRPCClient *jsonRpcClient;
    NBMJSONRPCClientConfiguration *clientConfig;
    SRWebSocket *webSocket;
    NSString *currentFrom;
    NSInteger callState;
}

@synthesize delegate;
@synthesize rtcPeer;

- (void)initClient:(NSURL *)wsURI {
    self.openChannelTimeout = kChannelTimeoutInterval;
    self.keepAliveInterval = kChannelKeepaliveInterval;
    self.processingQueue = dispatch_queue_create("eu.nubomedia.websocket.processing", DISPATCH_QUEUE_SERIAL);
    self.channelState = TransportChannelStateClosed;
    
    NSURLRequest *wsRequest = [[NSURLRequest alloc] initWithURL:wsURI cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_openChannelTimeout];
    SRWebSocket *newWebSocket = [[SRWebSocket alloc] initWithURLRequest:wsRequest protocols:@[] allowsUntrustedSSLCertificates:YES];
    [newWebSocket setDelegateDispatchQueue:self.processingQueue];
    newWebSocket.delegate = self;
    [newWebSocket open];
}

- (void) dealloc {
    [self close];
}

- (void)close {
    if (_channelState != TransportChannelStateClosed) {
        [webSocket close];
        self.channelState = TransportChannelStateClosing;
    }
    else {
        [self cleanupChannel];
    }
}

- (void)cleanupChannel
{
    webSocket.delegate = nil;
    webSocket = nil;
    self.channelState = TransportChannelStateClosed;
    
    [self invalidateTimer];
}

- (void)scheduleTimer
{
    [self invalidateTimer];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:self.keepAliveInterval target:self selector:@selector(handlePingTimer:) userInfo:nil repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    self.keepAliveTimer = timer;
}

- (void)invalidateTimer
{
    [_keepAliveTimer invalidate];
    _keepAliveTimer = nil;
}

- (void)handlePingTimer:(NSTimer *)timer
{
    if (webSocket) {
        [self sendPing];
        [self scheduleTimer];
    } else {
        [self invalidateTimer];
    }
}

- (void)sendPing
{
    //check for socket status
    if (webSocket.readyState == SR_OPEN) {
        NSLog(@"Send ping");
        [webSocket sendPing:nil];
        // [webSocket send:@"aa"];
    }
}

/*------------------------------------------------------------------------------
//  Send Command
------------------------------------------------------------------------------*/
- (void)registerUser:(NSString *)claimId UserId:(NSString *)userId Name:(NSString *)name{
    NSDictionary *param = @{@"ClaimID": claimId, @"UserID": userId, @"id": @"register", @"name": name};
    NSString *command = [param getJsonString:true];
    [self sendMessage:command];
    
    rtcPeer = [[RTCPeer alloc] init];
    [rtcPeer initPeer:self];
    rtcPeer.connectionId = name;
}
- (void)acceptCall {
    [rtcPeer generateOffer:rtcPeer.connectionId];
    
    self.localStream = rtcPeer.webRTCPeer.localStream;
    id<NBMRenderer> renderer = nil;
    RTCVideoTrack *videoTrack = [self.localStream.videoTracks firstObject];
    NBMRendererType rendererType = rtcPeer.webRTCPeer.mediaConfiguration.rendererType;
    
    if (rendererType == NBMRendererTypeOpenGLES) {
        renderer = [[NBMEAGLRenderer alloc] initWithDelegate:self];
    }
    renderer.videoTrack = videoTrack;
    
    self.localRenderer = renderer;
    
    [delegate onAddLocalStream:self.localRenderer.rendererView];
}

- (void)rejectCall:(NSString *)reason  {
    NSLog(@"call reject");
    NSDictionary *param = @{@"id": @"incomingCallResponse",
                            @"from": currentFrom,
                            @"callResponse": @"reject",
                            @"message": reason};
    NSString *command = [param getJsonString:true];
    [self sendMessage:command];
}

- (void)stopCall {
    NSLog(@"call stop");
    NSDictionary *param = @{@"id": @"stop"};
    NSString *command = [param getJsonString:true];
    [self sendMessage:command];
}

- (void)sendMessage:(NSString *)message {
    if (message) {
        if (_channelState == TransportChannelStateOpen) {
            DDLogVerbose(@"WebSocket: did send message: %@", message);
            [webSocket send:message];
        } else {
            DDLogWarn(@"Socket is not ready to send a message!");
        }
    }
}

/*------------------------------------------------------------------------------
//  JSON RPC Delegate
------------------------------------------------------------------------------*/

- (void)registerResponse:(NSDictionary *)message {
    NSString *response = [message objectForKey:@"response"];
    if ([response isEqualToString:@"accepted"]) {
        NSLog(@"Register Success");
    } else {
        NSLog(@"Register Error : %@", message);
    }
}

- (void)incomingCall:(NSDictionary *)message {
    NSString *from = [message objectForKey:@"from"];
    currentFrom = from;    
    if (callState != CALLSTATE_NO_CALL && callState != CALLSTATE_POST_CALL) {
        [self rejectCall:@"bussy"];
    } else {
        rtcPeer.fromUserId = currentFrom;
        [delegate onCallReceived:from];
    }
}

- (void)startCommunication:(NSDictionary *)message {
    NSString *sdpAnswer = [message objectForKey:@"sdpAnswer"];
    NSLog(@"Received Start Communication Message");
    [rtcPeer processAnswer:sdpAnswer];
    // [delegate onStartCommunication:rend];
}

- (void)stopCommunication {
    NSLog(@"stopCommunication called.");
    [self didRemoveRemoteStream];
    [delegate onStopCommunication];
}

- (void)iceCandidate:(NSDictionary *)message {
    NSDictionary *data = [message objectForKey:@"candidate"];
    NSString *sdpMid = [data objectForKey:@"sdpMid"];
    NSInteger sdpMLineIndex = [[data objectForKey:@"sdpMLineIndex"] integerValue];
    NSString *sdp = [data objectForKey:@"candidate"];

    RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:sdpMid
                                                                index:sdpMLineIndex
                                                                  sdp:sdp];
    [rtcPeer addICECandidate:candidate];
}

- (void)didAddRemoteStream: (RTCMediaStream*)remoteStream {
    self.remoteStream = remoteStream;
    id<NBMRenderer> renderer = nil;
    RTCVideoTrack *videoTrack = [self.remoteStream.videoTracks firstObject];
    NBMRendererType rendererType = rtcPeer.webRTCPeer.mediaConfiguration.rendererType;
    
    if (rendererType == NBMRendererTypeOpenGLES) {
        renderer = [[NBMEAGLRenderer alloc] initWithDelegate:self];
        renderer.videoTrack = videoTrack;
        self.remoteRenderer = renderer;
        [delegate onAddRemoteStream:self.remoteRenderer.rendererView];
    } else {
        NSLog(@"remote stream has not exact render type.");
    }
}

- (void)didRemoveRemoteStream {
    self.remoteStream = nil;
    self.remoteRenderer = nil;
    [delegate onRemoveRemoteStream];
}

/*------------------------------------------------------------------------------
 //  WebSocket Delegate
 ------------------------------------------------------------------------------*/

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
    webSocket = newWebSocket;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.channelState = TransportChannelStateOpen;
        //Keep-alive
        [self scheduleTimer];
    });
    NSLog(@"socket opened.");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"socket error. %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanupChannel];
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    dispatch_async(dispatch_get_main_queue(), ^{
    
        if (![message isKindOfClass:[NSString class]])
            return;
        NSError *jsonError;
        NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
        NSString *messageId = [data objectForKey:@"id"];
        NSLog(@"socket data received - %@", messageId);
        if ([messageId isEqualToString:@"resgisterResponse"]) {
            [self registerResponse:data];
        }
        if ([messageId isEqualToString:@"incomingCall"]) {
            [self incomingCall:data];
        }
        if ([messageId isEqualToString:@"startCommunication"]) {
            [self startCommunication:data];
        }
        if ([messageId isEqualToString:@"stopCommunication"]) {
            [self stopCommunication];
        }
        if ([messageId isEqualToString:@"iceCandidate"]) {
            if (data != nil) {
                [self iceCandidate:data];
            }
        }
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"socket closed.");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanupChannel];
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"ping received. ");
}


/*------------------------------------------------------------------------------
 //  WebSocket Delegate
 ------------------------------------------------------------------------------*/

- (void)renderer:(id<NBMRenderer>)renderer streamDimensionsDidChange:(CGSize)dimensions {
}

- (void)rendererDidReceiveVideoData:(id<NBMRenderer>)renderer {
}

@end