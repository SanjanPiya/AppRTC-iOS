//
//  ARTCRoomViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCRoomViewController.h"
#import "ARTCVideoChatViewController.h"

#define SERVER_HOST_URL @"ws://localhost:8080/jWebrtc"

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
   // [self.client register: SERVER_HOST_URL];
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
        [cell setDelegate:self];
        
        return cell;
    }
    
    return nil;
}



- (void)disconnect {
    if (self.client) {
      //  if (self.localVideoTrack) [self.localVideoTrack removeRenderer:self.localView];
      //  if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
      //  self.localVideoTrack = nil;
      //  [self.localView renderFrame:nil];
      //  self.remoteVideoTrack = nil;
     //   [self.remoteView renderFrame:nil];
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



- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [self disconnect];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ARTCVideoChatViewController *viewController = (ARTCVideoChatViewController *)[segue destinationViewController];
    [viewController setServerHostUrl: SERVER_HOST_URL];
}

#pragma mark - ARTCRoomTextInputViewCellDelegate Methods

- (void)toTextInputViewCell:(ARTCRoomTextInputViewCell *)cell shouldCallUser:(NSString *)to {
    [self performSegueWithIdentifier:@"ARTCVideoChatViewController" sender:to];
}

@end
