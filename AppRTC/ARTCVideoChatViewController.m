//
//  ARTCVideoChatViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCVideoChatViewController.h"
#import <AVFoundation/AVFoundation.h>

@implementation ARTCVideoChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.client.isZoom = NO;
    self.isAudioMute = NO;
    self.isVideoMute = NO;
    //RTCEAGLVideoViewDelegate provides notifications on video frame dimensions
    self.client.remoteView = self.remoteView;
    self.client.localView = self.localView ;
    self.client.localView.layer.zPosition = MAXFLOAT;
    self.client.viewWrapper = self.view;
    
    [self.audioButton.layer setCornerRadius:20.0f];
    [self.videoButton.layer setCornerRadius:20.0f];
    [self.hangupButton.layer setCornerRadius:20.0f];
    
    //Add Tap to hide/show controls
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleButtonContainer)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.client.viewWrapper addGestureRecognizer:tapGestureRecognizer];
    
    //Add Double Tap to zoom
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomRemote)];
    [tapGestureRecognizer setNumberOfTapsRequired:2];
    [self.client.viewWrapper addGestureRecognizer:tapGestureRecognizer];
    

    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];

    NSString *callingString;
    
    if (self.client.isInitiator){
        callingString = [NSString stringWithFormat:@"calling to %@", self.client.to];
        [self.urlLabel setText: callingString];
        NSLog(@"%@", callingString);
        [self.client call: self.client.from:  self.client.to];
        
    }else{
        callingString = [NSString stringWithFormat:@"call from %@", self.client.to];
        [self.urlLabel setText: callingString];
        NSLog(@"%@", callingString);
        [self.client startSignalingIfReady];
        
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    //Display the Local View full screen while connecting to Room (very good - but don't let the the remote video appear above the local video yet!)
    [self.localViewBottomConstraint setConstant:0.0f];
    [self.localViewRightConstraint setConstant:0.0f];
    [self.localViewHeightConstraint setConstant:self.view.frame.size.height];
    [self.localViewWidthConstraint setConstant:self.view.frame.size.width];
    [self.footerViewBottomConstraint setConstant:0.0f];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)disconnect {
    if (self.client) {
        if (self.client.localVideoTrack)[self.client.localVideoTrack removeRenderer: self.client.localView];
        if (self.client.remoteVideoTrack)[self.client.remoteVideoTrack removeRenderer:self.client.remoteView];
        self.client.localVideoTrack = nil;
        [self.client.localView renderFrame:nil];
        self.client.remoteVideoTrack = nil;
        [self.client.remoteView renderFrame:nil];
        [self.client disconnect: true ];
    }
}

- (void)remoteDisconnected {
    if (self.client.remoteVideoTrack) [self.client.remoteVideoTrack removeRenderer:self.client.remoteView];
    self.client.remoteVideoTrack = nil;
    [self.client.remoteView renderFrame:nil];
    [self videoView:self.client.localView didChangeVideoSize:self.localVideoSize];
}

- (void)toggleButtonContainer {
    [UIView animateWithDuration:0.3f animations:^{
        if (self.buttonContainerViewLeftConstraint.constant <= -40.0f) {
            [self.buttonContainerViewLeftConstraint setConstant:20.0f];
            [self.buttonContainerView setAlpha:1.0f];
        } else {
            [self.buttonContainerViewLeftConstraint setConstant:-40.0f];
            [self.buttonContainerView setAlpha:0.0f];
        }
        [self.view layoutIfNeeded];
    }];
}



- (void)zoomRemote {
    //Toggle Aspect Fill or Fit
    self.isZoom = !self.isZoom;
    [self videoView:self.client.remoteView didChangeVideoSize:self.remoteVideoSize];
}

- (IBAction)audioButtonPressed:(id)sender {
    //TODO: this change not work on simulator (it will crash)
    UIButton *audioButton = sender;
    if (self.isAudioMute) {
        [self.client unmuteAudioIn];
        [audioButton setImage:[UIImage imageNamed:@"audioOn"] forState:UIControlStateNormal];
        self.isAudioMute = NO;
    } else {
        [self.client muteAudioIn];
        [audioButton setImage:[UIImage imageNamed:@"audioOff"] forState:UIControlStateNormal];
        self.isAudioMute = YES;
    }
}

- (IBAction)videoButtonPressed:(id)sender {
    UIButton *videoButton = sender;
    if (self.isVideoMute) {
//        [self.client unmuteVideoIn];
        [self.client swapCameraToFront];
        [videoButton setImage:[UIImage imageNamed:@"videoOn"] forState:UIControlStateNormal];
        self.isVideoMute = NO;
    } else {
        [self.client swapCameraToBack];
        //[self.client muteVideoIn];
        //[videoButton setImage:[UIImage imageNamed:@"videoOff"] forState:UIControlStateNormal];
        self.isVideoMute = YES;
    }
}

- (IBAction)hangupButtonPressed:(id)sender {
    //Clean up
    [self disconnect];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
        case kARDAppClientIceFinished:
             NSLog(@"ICE  finished");
                [self videoView:client.localView didChangeVideoSize:self.localView.frame.size];
                [self videoView:client.remoteView didChangeVideoSize:self.remoteView.frame.size];
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            // [[self navigationController] setNavigationBarHidden:NO animated:YES];
            [self.navigationController popToRootViewControllerAnimated:YES];
            //  [self remoteDisconnected];
            break;
    }
}

- (void)orientationChanged:(NSNotification *)notification{
    [self videoView:self.client.localView didChangeVideoSize:self.localView.frame.size]; //self.localVideoSize (is not set anywhere ?!)
    [self videoView:self.client.remoteView didChangeVideoSize:self.remoteView.frame.size]; //self.remoteVideoSize (is not set anywhere !?!)
}



#pragma mark - RTCEAGLVideoViewDelegate
- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    
    if(self.client.localView.window != nil){
        NSLog(@"localView is there.");
    }
    
    if(self.remoteView.window != nil){
        NSLog(@"remoteView is there.");
    }
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [UIView animateWithDuration:0.4f animations:^{
        CGFloat containerWidth = self.client.viewWrapper.frame.size.width;
        CGFloat containerHeight = self.client.viewWrapper.frame.size.height;
        CGSize defaultAspectRatio = CGSizeMake(4, 3);
        if (videoView == self.client.localView) {
            //Resize the Local View depending if it is full screen or thumbnail
            self.localVideoSize = size;
            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
            CGRect videoRect = self.client.viewWrapper.bounds;
            if (self.client.remoteVideoTrack) {
                videoRect = CGRectMake(0.0f, 0.0f, self.client.viewWrapper.frame.size.width/4.0f, self.client.viewWrapper.frame.size.height/4.0f);
                if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
                    videoRect = CGRectMake(0.0f, 0.0f, self.client.viewWrapper.frame.size.height/4.0f, self.client.viewWrapper.frame.size.width/4.0f);
                }
            }
            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

            //Resize the localView accordingly
            [self.localViewWidthConstraint setConstant:videoFrame.size.width];
            [self.localViewHeightConstraint setConstant:videoFrame.size.height];
            if (self.client.remoteVideoTrack) {
                [self.localViewBottomConstraint setConstant:28.0f]; //bottom right corner
                [self.localViewRightConstraint setConstant:28.0f];
            } else {
                [self.localViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f]; //center
                 [self.localViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            }
        } else if (videoView == self.client.remoteView) {
            //Resize Remote View
            self.remoteVideoSize = size;
            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
            CGRect videoRect = self.client.viewWrapper.bounds;
            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);
            if (self.client.isZoom) {
                //Set Aspect Fill
                CGFloat scale = MAX(containerWidth/videoFrame.size.width, containerHeight/videoFrame.size.height);
                videoFrame.size.width *= scale;
                videoFrame.size.height *= scale;
            }
            [self.remoteViewTopConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
            [self.remoteViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
            [self.remoteViewLeftConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            [self.remoteViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            
        }
        [self.client.viewWrapper layoutIfNeeded];
    }];
}

@end
