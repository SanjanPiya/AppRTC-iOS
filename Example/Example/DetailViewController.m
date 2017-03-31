//
//  DetailViewController.m
//  Example
//
//  Created by David Linsin on 11/11/14.
//  Copyright (c) 2014 furryfishapps. All rights reserved.
//

#import "DetailViewController.h"
#import "ARDAppClient.h"
#import "ARTCVideoChatViewController.h"
#import "ADCallKitManager.h"

@interface DetailViewController ()

@end

@implementation DetailViewController


#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {

    //IncomingCallRequestNotification is when the called person calls us back (thats why its called incoming call)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(incomingCallRequest)
                                                 name:@"IncomingCallRequestNotification"
                                               object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) incomingCallRequest {
    /**
     * Start VideoChatViewController in MscWebRTC Pod by looking for its storyboard
     */
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

/*
- (void)someMethod
{
    [self methodAWithCompletion:^(BOOL success) {
        // check if thing worked.
    }];
}

- (void)methodAWithCompletion:(void (^) (BOOL success))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
        
        // go do something asynchronous...
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            completion(true);
            
        });
    });
}*/

- (IBAction)press:(id)sender {  //call
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
                [self.client connect : false : fromUUID];
                //[self.client sendCallOverThrift :  from : to : fromUUID : toUUID];
            }
        }
    };
    
    NSUUID *callUUID = [[ADCallKitManager sharedInstance] reportOutgoingCallWithContact:@"nico krause"
                                                          completion:startCallcompletion];
    
    [[ADCallKitManager sharedInstance] updateCall:callUUID state:ADCallStateConnecting];
}

@end
