        /*
 * libjingle
 * Copyright 2014, Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ARDAppClient.h"

#import <AVFoundation/AVFoundation.h>

#import "ARDMessageResponse.h"
#import "ARDRegisterResponse.h"
#import "ARDSignalingMessage.h"
#import "ARDUtilities.h"
#import "ARDWebSocketChannel.h"
#import "RTCICECandidate+JSON.h"
#import "RTCICEServer+JSON.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescription+JSON.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoTrack.h"


//static NSString *kARDDefaultSTUNServerUrl = @"stun:stun.l.google.com:19302";
static NSString *kARDDefaultSTUNServerUrl = @"stun:5.9.154.226:3478";

static NSString *kARDAppClientErrorDomain = @"ARDAppClient";
static NSInteger kARDAppClientErrorUnknown = -1;
static NSInteger kARDAppClientErrorRoomFull = -2;
static NSInteger kARDAppClientErrorCreateSDP = -3;
static NSInteger kARDAppClientErrorSetSDP = -4;
static NSInteger kARDAppClientErrorNetwork = -5;
static NSInteger kARDAppClientErrorInvalidClient = -6;
static NSInteger kARDAppClientErrorInvalidRoom = -7;

@interface ARDAppClient () <ARDWebSocketChannelDelegate,
RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>{
     NSMutableArray * arrayCondidates;
}
@property(nonatomic, strong) ARDWebSocketChannel *channel;
@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) NSMutableArray *messageQueue;
@property(nonatomic, assign) BOOL hasReceivedSdp;
@property(nonatomic, readonly) BOOL isRegisteredWithWebsocketServer;


@property(nonatomic, assign) BOOL isSpeakerEnabled;
@property(nonatomic, strong) NSMutableArray *iceServers;
@property(nonatomic, strong) NSURL *webSocketURL;
@property(nonatomic, strong) RTCAudioTrack *defaultAudioTrack;
@property(nonatomic, strong) RTCVideoTrack *defaultVideoTrack;



@end

@implementation ARDAppClient

@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize serverHostUrl = _serverHostUrl;
@synthesize channel = _channel;
@synthesize peerConnection = _peerConnection;
@synthesize factory = _factory;
@synthesize messageQueue = _messageQueue;
@synthesize hasReceivedSdp  = _hasReceivedSdp;
@synthesize isRegisteredWithWebsocketServer  = _isRegisteredWithWebsocketServer;
@synthesize from = _from;
@synthesize to = _to;
@synthesize isInitiator = _isInitiator;
@synthesize isSpeakerEnabled = _isSpeakerEnabled;
@synthesize iceServers = _iceServers;
@synthesize webSocketURL = _websocketURL;
@synthesize localVideoTrack = _localVideoTrack;
@synthesize remoteVideoTrack = _remoteVideoTrack;
@synthesize remoteView = _remoteView;
@synthesize localView = _localView;
@synthesize viewWrapper = _viewWrapper;

@synthesize localViewWidthConstraint = _localViewWidthConstraint;
@synthesize localViewHeightConstraint = _localViewHeightConstraint;
@synthesize localViewRightConstraint = _localViewRightConstraint;
@synthesize localViewBottomConstraint = _localViewBottomConstraint;
@synthesize footerViewBottomConstraint = _footerViewBottomConstraint;

- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate {
  if (self = [super init]) {
    _delegate = delegate;
    _factory = [[RTCPeerConnectionFactory alloc] init];
    _messageQueue = [NSMutableArray array];
    _iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
    _isSpeakerEnabled = YES;
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(orientationChanged:)
                                                   name:@"UIDeviceOrientationDidChangeNotification"
                                                 object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect : false];
}

- (void)orientationChanged:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if(_state == kARDAppClientStateDisconnected || _state == kARDAppClientStateConnecting){
        NSLog(@"orientation changed ");
        return;
    }
    
    if (UIDeviceOrientationIsLandscape(orientation) || UIDeviceOrientationIsPortrait(orientation)) {
        //Remove current video track
        RTCMediaStream *localStream = _peerConnection.localStreams[0];
        [localStream removeVideoTrack:localStream.videoTracks[0]];
        
        RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
        if (localVideoTrack) {
            [localStream addVideoTrack:localVideoTrack];
            [self didReceiveLocalVideoTrack:localVideoTrack];
        }
        [_peerConnection removeStream:localStream];
        [_peerConnection addStream:localStream];
    }
}

- (void)setState:(ARDAppClientState)state {
  if (_state == state) {
    return;
  }
  _state = state;
  [_delegate appClient:self didChangeState:_state];
}

- (void)connectToWebsocket:(NSString *)url : (NSString *)from {
  
    if (_channel != nil) {  //disconnect from call not from colider
        return;
    }
    NSParameterAssert(url.length);
    _websocketURL = [NSURL URLWithString:url];
    _from = from;
    NSParameterAssert(_state == kARDAppClientStateDisconnected);
    self.state = kARDAppClientStateConnecting;
  
    __weak ARDAppClient *weakSelf = self;
    ARDAppClient *strongSelf = weakSelf;
    [strongSelf registerWithColliderIfReady];
    
    [_channel getAppConfig];

    
}

- (void)call:(NSString *)from : (NSString *)to{
    self.to = to;
    self.from = from;
    [self startSignalingIfReady];
}



- (void)disconnect: (BOOL) ownDisconnect {
  if (_state == kARDAppClientStateDisconnected) {  //disconnect from call not from colider
    return;
  }
    if (_channel) {
    
    //check if this disconnect was issued by ourselfs - if so send our peer a message
    if (ownDisconnect) {
      // Tell the other client we're hanging up.
      ARDByeMessage *byeMessage = [[ARDByeMessage alloc] init];
      NSData *byeData = [byeMessage JSONData];
      [_channel sendData:byeData];
    }
  }

    _hasReceivedSdp = NO;
    _messageQueue = [NSMutableArray array];
    _peerConnection = nil;
    self.state = kARDAppClientStateDisconnected;
    
    [_delegate self ]; //.navigationController popToRootViewControllerAnimated:YES]
    //[_delegate navigationController popToRootViewControllerAnimated:YES];
   // [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - ARDWebSocketChannelDelegate

- (void)channel:(ARDWebSocketChannel *)channel
    setTurnServer:(NSArray *)turnServers {
    _iceServers = turnServers;
}

- (void)channel:(ARDWebSocketChannel *)channel
    didReceiveMessage:(ARDSignalingMessage *)message {
  switch (message.type) {
    case kARDSignalingMessageTypeRegisteredUsers:
          [_registeredUserdelegate updateTable:((ARDRegisteredUserMessage *)message).registeredUsers];
          break;
    case kARDSignalingMessageTypeRegister:
         // [_registeredUserdelegate updateTable:((ARDRegisteredUserMessage *)message).registeredUsers];
          break;
    case kARDSignalingMessageTypeResponse:
          
          break;
    case kARDSignalingMessageIncomingCall:
          _isInitiator = FALSE;
          _to = ((ARDIncomingCallMessage *)message).from; //the guy who is calling is "from" but its the new "to"!
          _hasReceivedSdp = YES;
          [_delegate appClient:self incomingCallRequest: ((ARDIncomingCallMessage *)message).from];
          break;
    
    case kARDSignalingMessageStartCommunication:
          _hasReceivedSdp = YES;
          [_messageQueue insertObject:message atIndex:0];
          
          break;

    case kARDSignalingMessageTypeOffer:
    case kARDSignalingMessageTypeAnswer:
      _hasReceivedSdp = YES;
      [_messageQueue insertObject:message atIndex:0];
      break;
    case kARDSignalingMessageTypeCandidate:
      [_messageQueue addObject:message];
      break;
    case kARDSignalingMessageTypeBye:
      [self processSignalingMessage:message];
      return;
  }
  [self drainMessageQueueIfReady];
}

- (void)channel:(ARDWebSocketChannel *)channel
    didChangeState:(ARDWebSocketChannelState)state {
  switch (state) {
    case kARDWebSocketChannelStateOpen:
      break;
    case kARDWebSocketChannelStateRegistered:
      break;
    case kARDWebSocketChannelStateClosed:
    case kARDWebSocketChannelStateError:
      // TODO(tkchin): reconnection scenarios. Right now we just disconnect
      // completely if the websocket connection fails.
          [self disconnect : false];
      break;
  }
}

#pragma mark - RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    signalingStateChanged:(RTCSignalingState)stateChanged {
  NSLog(@"Signaling state changed: %d", stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"Received %lu video tracks and %lu audio tracks",
        (unsigned long)stream.videoTracks.count,
        (unsigned long)stream.audioTracks.count);
    if (stream.videoTracks.count) {
        RTCVideoTrack *videoTrack = stream.videoTracks[0];
        [self didReceiveRemoteVideoTrack:videoTrack];
        if (_isSpeakerEnabled) [self enableSpeaker]; //Use the "handsfree" speaker instead of the ear speaker.
    }
  });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
        removedStream:(RTCMediaStream *)stream {
  NSLog(@"Stream was removed.");
}

- (void)peerConnectionOnRenegotiationNeeded:
    (RTCPeerConnection *)peerConnection {
  NSLog(@"WARNING: Renegotiation needed but unimplemented.");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    iceConnectionChanged:(RTCICEConnectionState)newState {

        switch (newState) {
                   case RTCICEConnectionCompleted:
                        NSLog(@"RTCICEConnectionCompleted");
                        break;
                    case RTCICEConnectionConnected:
                        NSLog(@"RTCICEConnectionConnected");
                        break;
                    default:
                        break;
        }
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    iceGatheringChanged:(RTCICEGatheringState)newState {
  NSLog(@"ICE gathering state changed: %d", newState);
       switch (newState) {
                    case RTCICEGatheringComplete:
                        for (ARDICECandidateMessage *message in arrayCondidates) {
                                [self sendSignalingMessage:message];
                            }
                    break;
       }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
  dispatch_async(dispatch_get_main_queue(), ^{
      
      if (!arrayCondidates) {
          arrayCondidates = [NSMutableArray array];
      }
      ARDICECandidateMessage *message =
        [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
    
       [arrayCondidates addObject:message];
      [self sendSignalingMessage:message];
  });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
}

#pragma mark - RTCSessionDescriptionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didCreateSessionDescription:(RTCSessionDescription *)sdp
                          error:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      NSLog(@"Failed to create session description. Error: %@", error);
        [self disconnect : false];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: @"Failed to create session description.",
      };
      NSError *sdpError =
          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorCreateSDP
                                 userInfo:userInfo];

        [self didError:sdpError];
      return;
    }
    [_peerConnection setLocalDescriptionWithDelegate:self
                                  sessionDescription:sdp];
    
      ARDSessionDescriptionMessage *message = [[ARDSessionDescriptionMessage alloc] initWithDescription:sdp];
      
      if(!self.isInitiator){
          [_channel incomingCallResponse: _to:  sdp];
      }else{
          [_channel call: _from: _to : sdp];
      }
  });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didSetSessionDescriptionWithError:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      NSLog(@"Failed to set session description. Error: %@", error);
        [self disconnect : false];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: @"Failed to set session description.",
      };
      NSError *sdpError =
          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorSetSDP
                                 userInfo:userInfo];
    //  [_delegate appClient:self didError:sdpError];
        [self didError:sdpError];
      return;
    }
    // If we're answering and we've just set the remote offer we need to create
    // an answer and set the local description.
    if (!_isInitiator && !_peerConnection.localDescription) {
      RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
      [_peerConnection createAnswerWithDelegate:self
                                    constraints:constraints];

    }
  });
}

#pragma mark - Private

- (BOOL)isRegisteredWithWebsocketServer {
    return _channel.state == kARDWebSocketChannelStateOpen || _channel.state == kARDWebSocketChannelStateRegistered;
}

- (void)startSignalingIfReady {
    
  if (!self.isRegisteredWithWebsocketServer) {
    return;
  }
  self.state = kARDAppClientStateConnected;

  // Create peer connection.
  RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
  _peerConnection = [_factory peerConnectionWithICEServers:_iceServers
                                               constraints:constraints
                                                  delegate:self];
    
  RTCMediaStream *localStream = [self createLocalMediaStream];
  
  [_peerConnection addStream:localStream]; //crash here? check turn config
  [self sendOffer];
}

- (void)sendOffer {
    [_peerConnection createOfferWithDelegate:self constraints:[self defaultOfferConstraints]];
}

- (void)waitForAnswer {
  [self drainMessageQueueIfReady];
}

- (void)drainMessageQueueIfReady {
  if (!_peerConnection || !_hasReceivedSdp) {
    return;
  }
    
  for (ARDSignalingMessage *message in _messageQueue) {
      [self processSignalingMessage:message];
  }
  [_messageQueue removeAllObjects];
}

- (void)processSignalingMessage:(ARDSignalingMessage *)message {
  
    NSParameterAssert(_peerConnection || message.type == kARDSignalingMessageTypeBye);
    
  switch (message.type) {
      case kARDSignalingMessageStartCommunication:{
          ARDStartCommunicationMessage *sdpMessage = (ARDStartCommunicationMessage *) message;
          [_peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdpMessage.sessionDescription];
          break;
      }
    case kARDSignalingMessageTypeAnswer:{
        ARDStartCommunicationMessage *sdpMessage = (ARDStartCommunicationMessage *) message;
     //   ARDSessionDescriptionMessage *sdpMessage =  (ARDSessionDescriptionMessage *)message; //old
        RTCSessionDescription *remoteDesc = sdpMessage.sessionDescription;

      [_peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteDesc];
        
      break;
    }
    case kARDSignalingMessageTypeCandidate: {
    
      ARDICECandidateMessage *candidateMessage =  (ARDICECandidateMessage *)message;
      [_peerConnection addICECandidate:candidateMessage.candidate];
    
      break;
    }
    case kARDSignalingMessageTypeBye:
      // Other client disconnected.
      // TODO(tkchin): support waiting in room for next client. For now just
      // disconnect.
          [self disconnect : false];
      
      break;
  }
}

- (void)sendSignalingMessage:(ARDSignalingMessage *)message {
    [self sendSignalingMessageToCollider:message];
}


- (RTCVideoTrack *)createLocalVideoTrack {
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local stream.
    // TODO(tkchin): local video capture for OSX. See
    // https://code.google.com/p/webrtc/issues/detail?id=3417.

    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE

    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the front camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}

- (RTCMediaStream *)createLocalMediaStream {
    RTCMediaStream* localStream = [_factory mediaStreamWithLabel:@"ARDAMS"];

    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        //[_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
         [self didReceiveLocalVideoTrack:localVideoTrack];
    }
    
    [localStream addAudioTrack:[_factory audioTrackWithID:@"ARDAMSa0"]];
    if (_isSpeakerEnabled) [self enableSpeaker];
    return localStream;
}

- (void) didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    if (self.localVideoTrack) {
    
     [self.localVideoTrack removeRenderer:self.localView];
     self.localVideoTrack = nil;
     [self.localView renderFrame:nil];
     }
     self.localVideoTrack = localVideoTrack;
     [self.localVideoTrack addRenderer:self.localView];
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
      self.remoteVideoTrack = remoteVideoTrack;
     [self.remoteVideoTrack addRenderer:self.remoteView];
     
     [UIView animateWithDuration:0.4f animations:^{
         //Instead of using 0.4 of screen size, we re-calculate the local view and keep our aspect ratio
         UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
         
         CGRect videoRect = CGRectMake(0.0f, 0.0f,
                                       self.viewWrapper.frame.size.width/4.0f,
                                       self.viewWrapper.frame.size.height/4.0f);
          if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
          videoRect = CGRectMake(0.0f, 0.0f, self.viewWrapper.frame.size.height/4.0f, self.viewWrapper.frame.size.width/4.0f);
          }
          CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(_localView.frame.size, videoRect);
          
          [self.localViewWidthConstraint setConstant:videoFrame.size.width];
          [self.localViewHeightConstraint setConstant:videoFrame.size.height];
          
          
          [self.localViewBottomConstraint setConstant:28.0f];
          [self.localViewRightConstraint setConstant:28.0f];
          [self.footerViewBottomConstraint setConstant:-80.0f];
          [self.viewWrapper layoutIfNeeded];
     }];
}

- (void)didError:(NSError *)error {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles:nil];
    [alertView show];
    [self disconnect : false];
}

#pragma mark - Collider methods

- (void)registerWithColliderIfReady {
    // Open WebSocket connection.
    _websocketURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_websocketURL, @"/ws"]];
    _channel =  [[ARDWebSocketChannel alloc] initWithURL:_websocketURL delegate:self];
}

- (void)sendSignalingMessageToCollider:(ARDSignalingMessage *)message {
  NSData *data = [message JSONData];
  [_channel sendData:data];
}


#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:nil
                   optionalConstraints:nil];
  return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
  return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
  NSArray *mandatoryConstraints = @[
      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
  ];
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:mandatoryConstraints
                   optionalConstraints:nil];
  return constraints;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
  NSArray *optionalConstraints = @[
      [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
  ];
  RTCMediaConstraints* constraints =
      [[RTCMediaConstraints alloc]
          initWithMandatoryConstraints:nil
                   optionalConstraints:optionalConstraints];
  return constraints;
}

- (RTCICEServer *)defaultSTUNServer {
  NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];
  return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                  username:@""
                                  password:@""];
}

#pragma mark - Audio mute/unmute
- (void)muteAudioIn {
    NSLog(@"audio muted");
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    self.defaultAudioTrack = localStream.audioTracks[0];
    [localStream removeAudioTrack:localStream.audioTracks[0]];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)unmuteAudioIn {
    NSLog(@"audio unmuted");
    RTCMediaStream* localStream = _peerConnection.localStreams[0];
    [localStream addAudioTrack:self.defaultAudioTrack];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
    if (_isSpeakerEnabled) [self enableSpeaker];
}

#pragma mark - Video mute/unmute
- (void)muteVideoIn {
    NSLog(@"video muted");
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    self.defaultVideoTrack = localStream.videoTracks[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)unmuteVideoIn {
    NSLog(@"video unmuted");
    RTCMediaStream* localStream = _peerConnection.localStreams[0];
    [localStream addVideoTrack:self.defaultVideoTrack];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}

#pragma mark - swap camera
- (RTCVideoTrack *)createLocalVideoTrackBackCamera {
    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    //AVCaptureDevicePositionFront
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionBack) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the back camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}
- (void)swapCameraToFront{
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];

    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
     //   [_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
           [self didReceiveLocalVideoTrack:localVideoTrack];
    }
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)swapCameraToBack{
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrackBackCamera];
    
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
           [self didReceiveLocalVideoTrack:localVideoTrack];
        //[_delegate appClient:self didReceiveLocalVideoTrack:localVideoTrack];
    }
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}

#pragma mark - enable/disable speaker

- (void)enableSpeaker {
   // [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  //  _isSpeakerEnabled = YES;
}

- (void)disableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    _isSpeakerEnabled = NO;
}

@end
