# AppRTC - iOS

##About
This Xcode project is a native wrapper prototype in order to communicate with kurentos media server. It works in conjunction with two other projects

There are also:
- a pure websocket AppRTC for Kurento: AppRTC-Kurento and
- a pure websocket AppRTC for Android: AppRTC-Android 

##Todo
- fix ios Connection Problem
    Possibilities:
    - enable ipv6 on le-space.de or 
    - create fast(!) server at amazon with IPv6
    - download libjingle from somewhere and try: e.g. 
        - https://github.com/chamara-dev/gate_libjingle_peerconnection/tree/master/libjingle_peerconnection

    - create webrtc.libs for ios with
        - https://webrtc.org/native-code/development/ and/or
        - https://webrtc.org/native-code/ios/
        - apprtc - client with new webrtc.libs for ios do not connect correctly 
                (websocket connection problem of ios whitelist? - no info.plist) 
    - ask webrtc mailing list
    - follow reactNative issue: https://github.com/oney/react-native-webrtc/issues/79
    - follow with ipv6/reflexiveIP 
            - https://bugs.chromium.org/p/webrtc/issues/detail?id=5871
            - https://github.com/oney/react-native-webrtc/issues/79


##Observations
- ios client did not connect well in travelercafé network (reflexive connectivity test failed: https://test.webrtc.org/)
    - trickle ice https://webrtchacks.com/trickle-ice/
    turn:numb.viagenie.ca
    - rfc6544 https://tools.ietf.org/html/rfc6544
    - rfc5245 https://tools.ietf.org/html/rfc5245
    - https://webrtc.org/troubleshooting/
    - https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
    - https://easyrtc.com/docs/guides/easyrtc_webrtc_problems.php
    - https://blogs.technet.microsoft.com/nexthop/2009/04/22/how-communicator-uses-sdp-and-ice-to-establish-a-media-channel/
    - http://stackoverflow.com/questions/32520255/building-ios-native-app-using-webrtc
    - https://medium.com/@TechStud/blab-how-to-configure-your-firewall-1c6675e86f7b#.432tmg89m
    https://tech.appear.in/2015/05/25/Getting-started-with-WebRTC-on-iOS/
    http://stackoverflow.com/questions/32520255/building-ios-native-app-using-webrtc
        https://github.com/aolszak/WebRTC-iOS
    - mail of someone with iOS problems fixing it with a couple of stun servers https://groups.google.com/forum/#!topic/kurento/FmHUXSv6n7M
    - problems in erricson mailinglist https://recordnotfound.com/openwebrtc-examples-EricssonResearch-68647/issues
    http://www.avaya.com/blogs/archives/2014/08/understanding-webrtc-media-connections-ice-stun-and-turn.html
    - WebRTC Reflexive Connectivity Problems  https://github.com/webrtc/testrtc/issues/176

##Build WebRTC-Libs
- https://github.com/pristineio/webrtc-build-scripts (stopped maintenance! don't use)
- http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/ (doesn't work!)

##Test-WebRTc
- https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
- https://test.webrtc.org/
- stun/turn servers: https://gist.github.com/yetithefoot/7592580

##WebRTC-Security 
- Security Considerations http://webrtc-security.github.io/

##Bugs
- (setup) sound cannot be disabled from phone while broadcasting sound 
- calling the phone - video does not appear instantly (after a shake it comes)
- calling from the phone - video appears full and after shake the small vindow comes too
- after stopping a call a user cannot be called again. Signalling is looking for sessions which do not exist anymore. It's not clear why it does so.

##Nice2Haves
- (setup) try multi URL selection list for urls and setups (for development, integration, productionq)
- play ring-tone when calling 

##Improveements & Checks 
-  websocket stays online when app goes in to background - also when no active video connectino 
- "waiting for answer" does not disappear (should be removed) 
- (sept) screen orientation change results in strange behavior - even sometimes connection breaks
- if phone goes offline does it unregister form server too? 

- iphone switches screen of after some minutes without activity (prevent)
- user nandi to be configured over gui  
- websocket url should be configured over gui
- don't display user nandi in listbox because it cannot be called
- Error-Handling:
    - if appConfig is in wrong format display a message
    - wrong-turn-config or server - app crashes here: ARDAppClient.h:416 [_peerConnection addStream:localStream]
    - if server not reachable print message (generally print response messages somewhere in a status field)

##Done
- 2016-09-09 - stopping session in phone stopps session in phone but not in browser (stop is not send to server! ) implement / improve delegate - https://www.youtube.com/watch?v=eNmZEXNQheE
- 2016-09-09  stopping session on browser does not stop session in phone (should go back) stop is send but probably not received.
- 2016-08-30 websocket stays online (audio too) when app goes in to background (when active video connection)
- 2016-08-26 putting username and url into iphone setup
- 2016-08-26 disable sound 
- 2016-08-16 user nandi configured in <center></center> place e.g. AppRTC/ARTCVideoChatViewController.m
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
* [WebRTC Codes wars]  https://webrtc.ventures/2015/09/how-the-webrtc-codec-wars-could-affect-your-real-time-media-business/
