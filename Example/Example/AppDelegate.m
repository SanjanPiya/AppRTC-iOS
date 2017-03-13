//
//  AppDelegate.m
//  Example
//
//  Created by David Linsin on 11/11/14.
//  Copyright (c) 2014 furryfishapps. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "ADCallKitManager.h"
#import <PushKit/PushKit.h>
@interface AppDelegate () <UISplitViewControllerDelegate,PKPushRegistryDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    [self voipRegistration];
    
    [[ADCallKitManager sharedInstance] setupWithAppName:@"MSCWebRTC" supportsVideo:YES actionNotificationBlock:^(CXCallAction * _Nonnull action, ADCallActionType actionType) {
    
     NSLog(@"setupWithAppName: action %@ %d ",[action callUUID], actionType  );
    
    }];
    
    return YES;
}

// Register for VoIP notifications
- (void) voipRegistration {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    PKPushRegistry * voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

// Handle updated push credentials
- (void) pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
    // Register VoIP push token (a property of PKPushCredentials) with server
    if(self.client == nil){
        
        self.client = [[ARDAppClient alloc] initWithDelegate:self];
        // [self.client connectToWebsocket : false];
       
        NSData *tokenData = [credentials token];
       
        NSString *token =  [self stringWithDeviceToken: tokenData];
        [self.client registerWithSwift: @"99999"  :token ];
        
    }
    
    NSLog(@"didUpdatePushCredentials: token:%@ type:",[credentials token], type);
}

- (void) pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
      NSLog(@"didInvalidatePushTokenForType:%@ type:", type);
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    // Process the received push
    NSString *fromName = [[payload dictionaryPayload] objectForKey:@"fromName"];
    NSLog(@"PushKit data fromName: %@ ",fromName);
    [[ADCallKitManager sharedInstance] reportIncomingCallWithContact:fromName completion:nil];
 
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - utils

- (NSString *)stringWithDeviceToken:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    return [token copy];
}

@end
