//
//  RTCPeer.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/5/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <KurentoToolbox/KurentoToolbox.h>
#import "NSDictionary+Json.h"
#import <SocketRocket/SRWebSocket.h>

@class WebRTCClient;
@interface RTCPeer : NSObject <NBMWebRTCPeerDelegate>

- (void)initPeer:(WebRTCClient *)client;
- (void)generateOffer:(NSString *)chatId;
- (void)processAnswer:(NSString *)sdpAnswer;
- (void)addICECandidate:(RTCICECandidate *)candidate;

@property (nonatomic, strong) NBMWebRTCPeer *webRTCPeer;
@property (nonatomic, strong) NSString *connectionId;
@property (nonatomic, strong) NSString *fromUserId;
@property (nonatomic, strong) WebRTCClient *client;

@end