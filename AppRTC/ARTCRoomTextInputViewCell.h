//
//  ARTCRoomTextInputViewCell.h
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AppRTC/ARDAppClient.h>


@protocol ARTCRoomTextInputViewCellDelegate;

@interface ARTCRoomTextInputViewCell : UITableViewCell <UITextFieldDelegate,ARDAppClientUpdateUserTableDelegate,UITableViewDataSource,UITableViewDelegate>

@property (assign, nonatomic) id <ARTCRoomTextInputViewCellDelegate> delegate;

@property (strong, nonatomic) NSArray *registeredUsers;
@property (strong, nonatomic) IBOutlet UIButton *joinButton;
@property (strong, nonatomic) IBOutlet UILabel *errorLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *errorLabelHeightConstraint; //used for animating
@property (strong, nonatomic) IBOutlet UITableView *userListTableView;

- (IBAction)touchButtonPressed:(id)sender;


@end

@protocol ARTCRoomTextInputViewCellDelegate<NSObject>
@optional
- (void)toTextInputViewCell:(ARTCRoomTextInputViewCell *)cell shouldCallUser:(NSString *)to;
@end