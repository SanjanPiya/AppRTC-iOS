//
//  ARTCRoomViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCRoomViewController.h"
#import "ARTCVideoChatViewController.h"


//#define SERVER_HOST_URL @"wss://192.168.11.81/jWebrtc"
//#define SERVER_HOST_URL @"ws://192.168.11.81:8080/jWebrtc"

    #define SERVER_HOST_URL @"wss://www.nicokrause.com/jWebrtc"
//#define SERVER_HOST_URL @"wss://www.nicokrause.com:8181/jWebrtc"
//www.nicokrause.com:8181/jWebrtc/ws
@implementation ARTCRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];


    //Connect to the room
    [self disconnect];
    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    [self.client connectToWebsocket: SERVER_HOST_URL];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        ARTCRoomTextInputViewCell *cell = (ARTCRoomTextInputViewCell *)[tableView dequeueReusableCellWithIdentifier:@"RoomInputCell" forIndexPath:indexPath];
      
        self.client.registeredUserdelegate = cell;
        [cell setDelegate:self];
        
        return cell;
    }
    
    return nil;
}



- (void)disconnect {
    if (self.client) {
        if (self.client.localVideoTrack) [self.client.localVideoTrack removeRenderer:self.client.localView];
        if (self.client.remoteVideoTrack) [self.client.remoteVideoTrack removeRenderer:self.client.remoteView];
        self.client.localVideoTrack = nil;
        [self.client.localView renderFrame:nil];
        self.client.remoteVideoTrack = nil;
        [self.client.remoteView renderFrame:nil];
        [self.client disconnect];
    }
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
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
         //   [self remoteDisconnected];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client incomingCallRequest:(NSString *)from {
    NSLog(@" incoming call from %@",from);
    NSString *message =  [NSString stringWithFormat:@"incoming call from %@", from];
    
    self.client.to = from;
    self.client.from = @"nandi";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incoming call..."
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Hangup"
                                          otherButtonTitles:@"Answer call",nil];
    [alert show];
    
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Cancel Tapped.");

        ARDIncomingCallResponseMessage *message = [[ARDIncomingCallResponseMessage alloc] init];
        message.from = self.client.to;
        
        [self.client sendSignalingMessageToCollider: message];
     
    }
    else if (buttonIndex == 1) {
        self.client.isInitiator = FALSE;
    
        [self.client startSignalingIfReady];
        [self performSegueWithIdentifier:@"ARTCVideoChatViewController" sender:self.client];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)param {
    ARTCVideoChatViewController *viewController = (ARTCVideoChatViewController *)[segue destinationViewController];
    [viewController setClient: param];
}

#pragma mark - ARTCRoomTextInputViewCellDelegate Methods

- (void)toTextInputViewCell:(ARTCRoomTextInputViewCell *)cell shouldCallUser:(NSString *)to {
    self.client.to = to;
    self.client.isInitiator = TRUE;
    [self performSegueWithIdentifier:@"ARTCVideoChatViewController" sender:self.client];
}

@end
