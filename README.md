# AppRTC - iOS implementation of the Google WebRTC Demo

## About
This Xcode project is a native wrapper prototype in order to communicate with kurentos media server.
It works in conjunction with two other projects
- AppRTC-Kurento-Example (Kurento Signaling Server in Java (NodeJS not fully implemented yet))
- AppRTC-Demo (The Android counterpart of this project)

##Todo
- test on server (does the video appear or not)

##bugs
- (setup) try multi URL selection list for urls and setups (for development, integration, production)
- (setup) sound cannot be disabled from phone while broadcasting sound 
- calling the phone - video does not appear instantly (after shake it comes)
- calling from the phone - video appears full and after shake (the small vindow comes too)
- stopping session on browser does not stop session in phone (should go back) stop is send but probably not received.
- stopping session in phone stopps session in phone but not in browser (stop is not send to server! )

##Improveements & Checks 
- does websocket stay online when going app goes into background?
- shaking video turns into connection problem
- "waiting for answer" does not disappear (should be removed)
- sound works video sometimes does not appear (no big no small window) 
- decline call from browser and handle it in app (also clear connections etc. (disconnect))
- (sept) screen orientation change results in strange behavior - even sometimes connection breaks
- if phone goes offline does it unregister form server too? 
- play sound when calling 
- iphone switches screen of after some minutes without activity (prevent)
- user nandi to be configured over gui  
- websocket url should be configured over gui
- don't display user nandi in listbox because it cannot be called
- Error-Handling:
    - if appConfig is in wrong format display a message
    - wrong-turn-config or server - app crashes here: ARDAppClient.h:416 [_peerConnection addStream:localStream]
    - if server not reachable print message (generally print response messages somewhere in a status field)

##Done
- 2016-08-26 putting username and url into iphone setup
- 2016-08-26 disable sound 
- 2016-08-16 user nandi configured in cente place e.g. AppRTC/ARTCVideoChatViewController.m
- 2016-07-19 ios app can receive calls and answer calls
- 2016-07-09 local video is displayed in app and in browser 
- 2016-07-08 creating local description and send it to server (call from to)
- 2016-07-06 added registeredUsers to Websocket 
- 2016-07-06 added RegisterResponse to Websocket
- 2016-07-05 registering current user at server session
- 2016-07-05 registering websocket during app start and reading appConfig (e.g. turn servers) via websockets

##Documentations read
- getting Started with WebRTC on iOS https://tech.appear.in/2015/05/25/Getting-started-with-WebRTC-on-iOS/
- ObjectiveC Properties http://rypress.com/tutorials/objective-c/properties

## Features
* Fully native objective-c 64-bit support
* pre-compiled libWebRTC.a (saves you hours of compiling)
* Starting in v1.0.2 we are now referencing pod libjingle_peerconnection maintained by Pristine.io that has a an automated libWebRTC.a build process
* Utilizes Cocoa Pod dependency management
* View Controllers to easily drop into your own project
* Exposed APIs to easily customize and adapt to your needs (see below for more details)
* Supports the most recent https://apprtc.appspot.com (October 2015)
* We also have a fork of the [Google AppRTC Web Server](https://github.com/ISBX/apprtc-server) that maintains full compatibility with this project

## Notes
The following resources were useful in helping get this project to where it is today:
* [How to get started with WebRTC and iOS without wasting 10 hours of your life](http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/)
* [hiroeorz's AppRTCDemo Project](https://github.com/hiroeorz/AppRTCDemo)
* [Pristine.io Automated WebRTC Building](http://tech.pristine.io/automated-webrtc-building/)

## Running the AppRTC App on your iOS Device
To run the app on your iPhone or iPad you can fork this repository and open the `AppRTC.xcworkspace` in Xcode and compile onto your iOS Device to check it out. By default the server address is set to https://apprtc.appspot.com.

## Using the AppRTC Pod in your App
If you'd like to incorporate WebRTC Video Chat into your own application, you can install the AppRTC pod:
```
pod install AppRTC
```
From there you can look at the `ARTCVideoChatViewController` class in this repo. The following steps below detail the specific changes you will need to make in your app to add Video Chat.
#### Initialize SSL Peer Connection
WebRTC can communicate securely over SSL. This is required if you want to test over https://apprtc.appspot.com. You'll need to modify your `AppDelegate.m` class with the following:

1. Import the RTCPeerConnectionFactory.h
 ```
#import "RTCPeerConnectionFactory.h"
```

2. Add the following to your `application:didFinishLaunchingWithOptions:` method:
 ```objective-c
    [RTCPeerConnectionFactory initializeSSL];
```

3. Add the following to your `applicationWillTerminate:` method:
 ```objective-c
    [RTCPeerConnectionFactory deinitializeSSL];
```

#### Add Video Chat
To add video chat to your app you will need 2 views:
* Local Video View - Where the video is rendered from your device camera
* Remote Video View - where the video is rendered for the remote camera

To do this, perform the following:

1. In your ViewController or whatever class you are using that contains the 2 views defined above add the following headers imports:
 ```objective-c
#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <AppRTC/ARDAppClient.h>
```

2. The class should implement the `ARDAppClientDelegate` and `RTCEAGLVideoViewDelegate` protocols:
 ```objective-c
@interface ARTCVideoChatViewController : UIViewController <ARDAppClientDelegate, RTCEAGLVideoViewDelegate>
```
    * `ARDAppClientDelegate` - Handles events when remote client connects and disconnect states. Also, handles events when local and remote video feeds are received.
    * `RTCEAGLVideoViewDelegate` - Handles event for determining the video frame size.
    
3. Define the following properties in your class:
 ```objective-c
@property (strong, nonatomic) ARDAppClient *client;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *localView;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
```
    * *ARDAppClient* - Performs the connection to the AppRTC Server and joins the chat room
    * *remoteView* - Renders the Remote Video in the view
    * *localView* - Renders the Local Video in the view
    
4. When initializing the the property variables make sure to set the delegates:
 ```objective-c
    /* Initializes the ARDAppClient with the delegate assignment */
    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    
    /* RTCEAGLVideoViewDelegate provides notifications on video frame dimensions */
    [self.remoteView setDelegate:self];
    [self.localView setDelegate:self];
```

5. Connect to a Video Chat Room
 ```objective-c
    [self.client setServerHostUrl:@"https://apprtc.appspot.com"];
    [self.client connectToRoomWithId:@"room123" options:nil];
```

6. Handle the delegate methods for `ARDAppClientDelegate`
 ```objective-c
- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self remoteDisconnected];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    self.localVideoTrack = localVideoTrack;
    [self.localVideoTrack addRenderer:self.localView];
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    self.remoteVideoTrack = remoteVideoTrack;
    [self.remoteVideoTrack addRenderer:self.remoteView];
}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    /* Handle the error */
}
```

7. Handle the delegate callbacks for `RTCEAGLVideoViewDelegate`
 ```objective-c
- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
 /* resize self.localView or self.remoteView based on the size returned */
}
```


## Contributing
If you'd like to contribute, please fork the repository and issue pull requests. If you have any special requests and want to collaborate, please contact me directly. Thanks!

## Known Issues
The following are known issues that are being worked and should be released shortly:
* None at this time
