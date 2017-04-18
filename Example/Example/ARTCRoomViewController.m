//
//  ARTCRoomViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Modified by Nico Krause 2016-12-03
//
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCRoomViewController.h"
#import "ARTCVideoChatViewController.h"


@implementation ARTCRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
   
    [[self navigationController] setNavigationBarHidden:NO animated:YES];

    
    NSLog(@"connecting to the signaling server");
    //Connect to the room
    if(self.client == nil){
        self.client = [[ARDAppClient alloc] initWithDelegate:self];
        [self.client connect : false : nil];
    }
    
    [super viewWillAppear:animated];
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
        ARTCRoomTextInputViewCell *cell = (ARTCRoomTextInputViewCell *)[tableView dequeueReusableCellWithIdentifier:@"RoomInputCell" forIndexPath:indexPath];
      
        self.client.registeredUserdelegate = cell;
        [cell setDelegate:self];
        
        return cell;
}



- (void)disconnect {
    if (self.client) {
        if (self.client.localVideoTrack) [self.client.localVideoTrack removeRenderer:self.client.localView];
        if (self.client.remoteVideoTrack) [self.client.remoteVideoTrack removeRenderer:self.client.remoteView];
        self.client.localVideoTrack = nil;
        [self.client.localView renderFrame:nil];
        self.client.remoteVideoTrack = nil;
        [self.client.remoteView renderFrame:nil];
        [self.client disconnect:true useCallback:false];
    }
}

#pragma mark - ARDAppClientDelegate
- (void) appClient:(ARDAppClient *)client didChangeSignalingState:(ARDAppClientState)state {
    
}

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
             [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        case kARDAppClientIceFinished:
            NSLog(@"Client connecting.");
            break;
    }
}

- (void)appClient:(ARDAppClient *)client incomingCallRequest:(NSString *)from {
    NSLog(@" incoming call from %@",from);
    NSString *message =  [NSString stringWithFormat:@"incoming call from %@", from];
    
    self.client.to = from;
    self.client.from = [[NSUserDefaults standardUserDefaults] stringForKey:@"MY_USERNAME"];
    if(false){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incoming call..."
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Hangup"
                                              otherButtonTitles:@"Answer call",nil];
        [alert show];
    }
    else{
        self.client.isInitiator = FALSE;
        
        [self performSegueWithIdentifier:@"ARTCVideoChatViewController" sender:self.client];
    }

    
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
