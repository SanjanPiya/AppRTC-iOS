# MSCRTC - iOS

##About
This Xcode project is a native wrapper prototype in order to communicate with kurentos media server. It works in conjunction with two other projects

There are also:
- a pure websocket AppRTC for Kurento: AppRTC-Kurento and
- a pure websocket AppRTC for Android: AppRTC-Android 

##Documentation
This WebRTC iOS App simply connects to a Java Webrtc Signaling Server via Websocket Protokoll and lists connected users which can be called via Videophone. It is a WebRTC-ready prototype for an integration into other apps which want to implement WebRTC Videocalls e.g. for their Sales and Support team. 

##Installation
1. git clone this repository and open it in X-Code
2. AppRTC-Kurento (Signaling Server) must be running already
3. STUN-TURN Server should be running, if you run the project outside your local LAN.
4. connect your iOS phone via USB and deploy and start app from X-Code 
5. in the app settings (iPhone - Settings - mscwebrtc) 
    - change the Websocket-URL according to the URL of your signaling server 
        e.g. wss://webrtcsignaling-server/jWebrtc (secure websocket - wss:// insecure with ws:// )
        you can change the default values in settings.bundle ROOT.plist
    - enter your favourite username which should register on signaling server and should be visible and reachable by the peers
6. open chrome and/or android browser to https://webrtcsignaling-server/jWebrtc and register another user
7. choose a registered user on phone or browser and call.

##Code-Instructions:
- the apps main controllers are
    - ARTCRoomViewController - displays the userlist for calling the users
    - ARTCVideoChatViewController - displays the videochat view incl. controlls
- websocket controller for signaling - ARDWebsocketChannel
- main app logic for WebRTC - ARDAppClient

##Todo/Bugs
- implement background websocket
- when receiving "rejected" do not send channel close to other party and display reject message"
- wrong connection url or other connection error does not show error
##Improvements


##Nice2Haves
- play ring-tone when calling and create "pop over" in apps (see whats app)
- let websocket go into background mode and handle it as voip socket
    - example void socket in background
        http://stackoverflow.com/questions/5987495/how-to-maintain-voip-socket-connection-in-background
        http://stackoverflow.com/questions/22366038/socketrocket-connection-pausing-while-in-background
        http://stackoverflow.com/questions/5987495/how-to-maintain-voip-socket-connection-in-background
        https://www.raywenderlich.com/29948/backgrounding-for-ios
        https://github.com/facebook/SocketRocket/issues/152
        http://stackoverflow.com/questions/28619881/ios-voip-socket-does-not-work-in-background-until-handler-is-fired
        http://stackoverflow.com/questions/5987495/how-to-maintain-voip-socket-connection-in-background
        http://stackoverflow.com/questions/27631748/configuring-ios-voip-application-to-run-in-sleep-background-mode
        http://stackoverflow.com/questions/12057151/voip-socket-on-ios-no-notifications-received
    - network service types of nsurlrequest
        https://github.com/facebook/SocketRocket/pull/293
    - https://developer.apple.com/library/content/documentation/iPhone/Conceptual/  iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW1 
    - https://github.com/facebook/SocketRocket/pull/275
    - update socketrocket? https://cocoapods.org/?q=on%3Aios%20socketrocket
- (extern) add "audio call" and "video call" button
- (extern) add "answer with audio" and answer "answer with video" button during incoming call 
- separate stream for screensharing
    - screensharing tab on small window (with remote video) moves in fullscreen and screensharing in smallscreen
    - screensharing tab on small window (with screen video) moves in fullscreen and remotevideo in smallscreen


- (setup) try multi URL selection list for urls and setups (for development, integration, productionq)

##Improvements & Checks 
- if url is not reachable or user already registered print error message
- if phone goes offline does it unregister form server too? 
- don't display own user in listbox because it cannot be called
- Error-Handling:
    - if appConfig is in wrong format display a message
    - wrong-turn-config or server - app crashes here: ARDAppClient.h:416 [_peerConnection addStream:localStream]
    - if server not reachable print message (generally print response messages somewhere in a st
    atus field)

##Build WebRTC-Libs
- current https://github.com/Anakros/WebRTC-iOS
- https://github.com/pristineio/webrtc-build-scripts (stopped maintenance! don't use)
- http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/ (doesn't work!)

##Test-WebRTC
- https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
- https://test.webrtc.org/
- stun/turn servers: https://gist.github.com/yetithefoot/7592580

##WebRTC-Security 
- Security Considerations http://webrtc-security.github.io/

##Done
- 2017-01-05 - implement background2front reconncect and register
- 2017-01-05 - implement ping-pong 
- 2016-12-17 - ios-code remove warnings (incompatible type, incompatible pointer)

- 2016-12-04 - screensharing needs to pop up fullscreen (instead of in small window)
- 2016-12-04 - screensharing small window needs to show remote video in right proportion
- 2016-12-04 - fixed call from Android (eventuelly from iPhone too) does not have right proportion (aspect ratio), webbrowser works!  
- 2016-12-04 - implemented stopCommunication function for proper receiving screensharing stop / start stream
- 2016-12-02 - implemented code for separate screensharing stream over separate peerconnection
- 2016-11-25 - camera symbol switches camera of on
- 2016-11-25 - disable zoom (for now)
- 2016-11-25 - double touch for camera change (like periscope)
- 2016-10-26 - handsfree speaker test switch with earpiece 
- 2016-10-26 - video during communication with firefox or chrome not blurred/stretched anymore. (1 MT)
- 2016-10-26 - orientation-change during call fast and smooth (1 MT)
- 2016-10-25 - removed websocket disconnect after hangup
- 2016-10-24 - (p1) iOS-Websocket does not wake up 
                https://github.com/jmesnil/stomp-websocket/issues/81
                http://stackoverflow.com/questions/3712979/applicationwillenterforeground-vs-applicationdidbecomeactive-applicationwillre
- 2016-10-18 - re-enabled camera switch (front-back cam)
- 2016-10-18 - re-enabled mute switch (sound cannot be disabled from phone while broadcasting sound) 
- 2016-10-18 - re-installed stable webrtc pod since pre-release used wrong camera orientation
- 2016-10-12 - iphone switches screen of after some minutes without activity (prevent)
- 2016-10-12 - removed old libjingle implementation and replaced it with new WebRTC.framework pod https://cocoapods.org/pods/WebRTC 
    - generall information on ios
        - http://quickblox.com/developers/Sample-webrtc-ios
    - Try Kurento-iOS 
        - https://media.readthedocs.org/pdf/kurento-ios/latest/kurento-ios.pdf
    - probably stun is not beeing used - instead it uses TURN change WebRTC-Library
        - https://github.com/Anakros/WebRTC-iOS
        - https://github.com/nubomediaTI/Kurento-iOS
    - framerate and bandwith issues on iOS
        - example to change height-width + framerate https://bugs.chromium.org/p/webrtc/issues/detail?id=4192
        - bitrates @ webrtc-experiment https://www.webrtc-experiment.com/webrtcpedia/
        - bandwidths example http://stackoverflow.com/questions/16712224/how-to-control-bandwidth-in-webrtc-video-call
    - orientation change between potrait an landscape not tested (has probably problems don't try!) 
- 2016-10-11 - iOS is not as fluent as Android 
- 2016-10-11 - rejecting a call from peer does not result in a stop connection on ios.
- 2016-10-04 - call-test-sequence c) Chrome2iPhoneHangupChrome --> d) Chrome2iPhoneHangupiPhone did not work 
                after stopping a call a user sometimes cannot be called again. Signalling is looking for sessions which do not exist anymore. It's not clear why. If the user who hangsup whants to call again he can't the session of the caller cannot be found anymore.
- 2016-10-03   - iOS RemoteVideo freezes in certain situations seems like this bug is related with 
               - iOS freezes only while communicating with a chrome (not with android not with firefox)
               - update kurento
- 2016-09-29    - app goes in stand-by mode after some time during video broadcast
                - app goes in stand-by mode and closes websocket 
                - websocket stays online when app goes in to background - also when no active video connectino 
- "waiting for answer" does not disappear (should be removed) 
- 2016-09-15    - calling the phone - video does not appear instantly (after a shake it comes)
                - calling from the phone - video appears full and after shake the small vindow comes too
                - miniLocalVideoDoesNotAppear / RemoteVideo does not appear   
- 2016-09-12 - fix ios Connection Problem
                Possibilities:
                - enable ipv6 on le-space.de
                    -- Update: ipv6 is enabled(!) - but cannot be pingt from #pipoca nor from #webrtc.a-fk.de -- need network which can ping IPv6  
                - create fast(!) server at amazon with IPv6 
                    -- Update: amazon with IPv6 does not work if I sit inside of a not ipv6 routed NAT.
                - download libjingle from somewhere and try: e.g. 
                    - https://github.com/chamara-dev/gate_libjingle_peerconnection/tree/master/libjingle_peerconnection

                - create webrtc.libs for ios with
                    - https://webrtc.org/native-code/development/ and/or
                    - https://webrtc.org/native-code/ios/
                    - apprtc - client with new webrtc.libs for ios do not connect correctly 
                            (websocket connection problem of ios whitelist? - no info.plist) 
                - ask webrtc mailing list
                - check creator of forked project 
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
