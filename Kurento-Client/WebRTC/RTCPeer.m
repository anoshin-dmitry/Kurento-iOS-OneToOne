//
//  RTCPeer.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/5/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libjingle_peerconnection/RTCICECandidate.h>
#import <libjingle_peerconnection/RTCSessionDescription.h>
#import "RTCPeer.h"
#import "WebRTCClient.h"


@implementation RTCPeer {
    int nICECandidateSocketSendCount;
}

@synthesize webRTCPeer;
@synthesize connectionId;
@synthesize fromUserId;

- (void)initPeer:(WebRTCClient *)client {
    NBMMediaConfiguration *mediaConfig = [NBMMediaConfiguration defaultConfiguration];
    webRTCPeer = [[NBMWebRTCPeer alloc] initWithDelegate:self configuration:mediaConfig];
    self.client = client;
    nICECandidateSocketSendCount = 0;
}

- (void)generateOffer:(NSString *)chatId {
    connectionId = chatId;
    [webRTCPeer generateOffer:connectionId];
}
- (void)processAnswer:(NSString *)sdpAnswer {
    [webRTCPeer processAnswer:sdpAnswer connectionId:connectionId];
}

- (void)addICECandidate:(RTCICECandidate *)candidate {
    [webRTCPeer addICECandidate:candidate connectionId:connectionId];    
}

- (NSString*) stringForICEConnectionState:(RTCICEConnectionState)state{
    switch (state) {
        case RTCICEConnectionNew:
            return @"New";
            break;
        case RTCICEConnectionChecking:
            return @"Checking";
            break;
        case RTCICEConnectionConnected:
            return @"Connected";
            break;
        case RTCICEConnectionCompleted:
            return @"Completed";
            break;
        case RTCICEConnectionFailed:
            return @"Failed";
            break;
        case RTCICEConnectionDisconnected:
            return @"Disconnected";
            break;
        case RTCICEConnectionClosed:
            return @"Closed";
            break;
        default:
            return @"Other state";
            break;
    }
}

- (NSString*) stringForSocketReadyState:(SRReadyState) readyState {
    if (readyState == SR_CONNECTING) {
        return @"Socket Connecting";
    } else if (readyState == SR_OPEN) {
        return @"Socket Open";
    } else if (readyState == SR_CLOSING) {
        return @"Socket Closing";
    } else if (readyState == SR_CLOSED) {
        return @"Socket Closed";
    } else {
        return @"Socket State Unknown";
    }
}
/**
 *  Called when the peer successfully generated an new offer for a connection.
 *
 *  @param peer       The peer sending the message.
 *  @param sdpOffer   The newly generated RTCSessionDescription offer.
 *  @param connection The connection for which the offer was generated.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didGenerateOffer:(RTCSessionDescription *)sdpOffer forConnection:(NBMPeerConnection *)connection {
    NSDictionary *message = @{@"id" : @"incomingCallResponse",
                              @"from" : fromUserId,
                              @"callResponse" : @"accept",
                              @"sdpOffer" : sdpOffer.description};
    NSLog(@"onLocalSdpOfferGenerated");
    [self.client sendMessage:[message getJsonString:false]];
}

/**
 *  Called when the peer successfully generated a new answer for a connection.
 *
 *  @param peer       The peer sending the message.
 *  @param sdpAnswer  The newly generated RTCSessionDescription offer.
 *  @param connection The connection for which the aswer was generated.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didGenerateAnswer:(RTCSessionDescription *)sdpAnswer forConnection:(NBMPeerConnection *)connection {
    NSDictionary *message = @{@"id" : @"incomingCallResponse",
                              @"from" : fromUserId,
                              @"callResponse" : @"accept",
                              @"sdpOffer" : sdpAnswer.description};
    NSLog(@"onLocalSdpAnswerGenerated");
    [self.client sendMessage:[message getJsonString:false]];
}

/**
 *  Called when a new ICE is locally gathered for a connection.
 *
 *  @param peer       The peer sending the message.
 *  @param candidate  The locally gathered ICE.
 *  @param connection The connection for which the ICE was gathered.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer hasICECandidate:(RTCICECandidate *)candidate forConnection:(NBMPeerConnection *)connection {
    
    NSDictionary *payload = @{@"sdpMLineIndex" : [NSNumber numberWithInteger:candidate.sdpMLineIndex],
                              @"sdpMid" : candidate.sdpMid,
                              @"candidate" : candidate.sdp};
    NSDictionary *message = @{@"id" : @"onIceCandidate",
                              @"candidate" : payload};
    NSLog(@"Send content: %@", [message getJsonString:false]);
    [self.client sendMessage:[message getJsonString:false]];
}

/**
 *  Called any time a connection's state changes.
 *
 *  @param peer       The peer sending the message.
 *  @param state      The new notified state.
 *  @param connection The connection whose state has changed.
 */
- (void)webrtcPeer:(NBMWebRTCPeer *)peer iceStatusChanged:(RTCICEConnectionState)state ofConnection:(NBMPeerConnection *)connection {
    NSLog(@"ICE status changed: %@", [self stringForICEConnectionState:state]);
}

/**
 *  Called when media is received on a new stream from remote peer.
 *
 *  @param peer         The peer sending the message.
 *  @param remoteStream A RTCMediaStream instance.
 *  @param connection   The connection related to the stream.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didAddStream:(RTCMediaStream *)remoteStream ofConnection:(NBMPeerConnection *)connection {
    NSLog(@"Added Stream");
    [self.client didAddRemoteStream:remoteStream];
}

/**
 *  Called when a remote peer close a stream.
 *
 *  @param peer         The peer sending the message.
 *  @param remoteStream A RTCMediaStream instance.
 *  @param connection   The connection related to the stream.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didRemoveStream:(RTCMediaStream *)remoteStream ofConnection:(NBMPeerConnection *)connection {
    NSLog(@"Removed Stream");
    [self.client didRemoveRemoteStream];
}

@end