# mscrtc


## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

storyboards-sample is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "mscrtc"

##	Components
1. Code for outgoing calls
1.1 add incoming call request notification
```objectivec
    - (void)viewDidLoad {

     //IncomingCallRequestNotification is when the called person calls us back (thats why its called incoming call)
     [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(incomingCallRequest)
                                                 name:@"IncomingCallRequestNotification"
                                               object:nil];
     }

	/**
  	 * Start VideoChatViewController in MscWebRTC Pod by looking for its storyboard
	 */
     - (void) incomingCallRequest {

     NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[ARDAppClient class]] URLForResource:@"mscrtc" withExtension:@"bundle"]];
    
     UIStoryboard *storyboard = [UIStoryboard
                                 storyboardWithName:@"MSCWebRTC" bundle:bundle];
    
     UIViewController *uvc = [storyboard instantiateViewControllerWithIdentifier:@"Video"];
     
     UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:uvc];
     
     ARTCVideoChatViewController *videoChatViewController = navCon.viewControllers[0];
     videoChatViewController.client = self.client;
    
     [self presentViewController:navCon animated:YES completion:nil];
    
     //if there is no controller here try this
     //[self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
    
     //or checkout standard seq
     // [self performSegueWithIdentifier:@"ARTCVideoChatViewController" sender:self];
}
```
1.2 add code for the call button
```objectivec
- (IBAction)call:{  //call
    /**
     * Report Outgoing-Call to Callkit
     */
    ADCallKitManagerCompletion startCallcompletion =^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"requestTransaction error %@", error);
             [self.client disconnect];
        }else{
            //start signaling
            NSString *from = @"999999";
            NSString *to = @"0015537";
            NSString *fromUUID = [[NSUUID UUID] UUIDString];
            NSString *toUUID = [[NSUUID UUID] UUIDString];
           
            
            if(self.client == nil){
                self.client = [[ARDAppClient alloc] initWithDelegate:[ADCallKitManager sharedInstance]];
                [self.client connectToWebsocket : false : fromUUID];
                [self.client sendCallOverThrift :  from : to : fromUUID : toUUID];
            }
        }
    };
    
    NSUUID *callUUID = [[ADCallKitManager sharedInstance] reportOutgoingCallWithContact:@"nico krause"
                                                          completion:startCallcompletion];
    
    [[ADCallKitManager sharedInstance] updateCall:callUUID state:ADCallStateConnecting];
}
```



2. Code for incoming calls (AppDelegate.m) for CallKit and PushKit
```objectivec
#import "ADCallKitManager.h"
#import <PushKit/PushKit.h>
#import "ARTCVideoChatViewController.h"

@implementation AppDelegate 
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [self voipRegistration];
    [self callkitRegistration];
    
    return YES;
}

// CallKit Registration
- (void) callkitRegistration {
    [[ADCallKitManager sharedInstance]
     setupWithAppName:@"MSCWebRTC"
     supportsVideo:YES
     actionNotificationBlock:^(CXCallAction * _Nonnull action, ADCallActionType actionType) {
        NSLog(@"ADCallKitManager: other action: %@ type: %ld  ",[action callUUID], (long)actionType  );
        if(actionType == ADCallActionTypeAnswer){
            
            //Start VideoChatViewController in MscWebRTC Pod
            NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[ARDAppClient class]]
                                                        URLForResource:@"mscrtc" withExtension:@"bundle"]];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MSCWebRTC" bundle:bundle];
            UIViewController *uvc = [storyboard instantiateViewControllerWithIdentifier:@"Video"];
            
            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:uvc];
            
            ARTCVideoChatViewController *videoChatViewController = navCon.viewControllers[0];
            videoChatViewController.client = self.client;
            
            [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
        }else{
            [self.client disconnect];
        }
        
    }];
}

// Handle updated push credentials
- (void) pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
    // Register VoIP push token (a property of PKPushCredentials) with server
    
    NSString *myUserId = @"99999";
    
    if(self.client == nil){
        self.client = [[ARDAppClient alloc] initWithDelegate:[ADCallKitManager sharedInstance]];
        
        //if we use pushkit the initiater becomes true when we receive a call in that case we manipulate the json of the websocket. Then it is doing the "callResponse" via a 'direct' call to the other party without any call answer dialog as usable (confusing?!)
        self.client.isPushKitConfig = true;
        
        NSData *tokenData = [credentials token];
        NSString *token =  [self stringWithDeviceToken: tokenData];
        [self.client registerWithSwift:  myUserId :token ];
    }
    
    NSLog(@"didUpdatePushCredentials: token:%@ type:%@",[credentials token], type);
}

- (void) pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
      NSLog(@"didInvalidatePushTokenForType:%@ type:", type);
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {

    NSString *fromName = [[payload dictionaryPayload] objectForKey:@"fromName"];
    NSString *toName = [[payload dictionaryPayload] objectForKey:@"toName"];
    NSString *fromUUID = [[payload dictionaryPayload] objectForKey:@"toUUID"];
    NSString *toUUID = [[payload dictionaryPayload] objectForKey:@"fromUUID"];
    
    NSLog(@"PushKit data fromName: %@ toName %@ ",fromName, toName);
    
    //Start 
    ADCallKitManagerCompletion startIncomingCallcompletion =^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"requestTransaction error %@", error);
        }else{
            self.client = [[ARDAppClient alloc] initWithDelegate:[ADCallKitManager sharedInstance]];
            self.client.from = fromUUID;
            self.client.to = toUUID;
            self.client.isPushKitConfig = true;
            self.client.isInitiator = true; //if we receive a push message from apple we switch the role of beeing the initiater of the call. We become initiater although the other party was calling! a bit confusing but practical. "outgoing" call needs to be accepted from the other party immediately so no dialog of "incoming call" is appearing there anymore. for that reason we set the direct call flag in the websocket signaling 'call' to true. if the client receives this he will connect the call directly without asking.
            [self.client connectToWebsocket : false : nil];          
        }
    };

    //Start CallKit
    [[ADCallKitManager sharedInstance] reportIncomingCallWithContact:fromName
                                                          completion:startIncomingCallcompletion];
 
}	
```


## Author

Nico Krause

## License

All rights reserved.
