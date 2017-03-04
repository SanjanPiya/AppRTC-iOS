//
//  ARTCRoomTextInputViewCell.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCRoomTextInputViewCell.h"

@implementation ARTCRoomTextInputViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.errorLabelHeightConstraint setConstant:0.0f];
    //[self.textField setDelegate:self];
    //[self.textField becomeFirstResponder];
    [self.joinButton setBackgroundColor:[UIColor colorWithWhite:100.0f/255.0f alpha:1.0f]];
    [self.joinButton setEnabled:NO];
    [self.joinButton.layer setCornerRadius:3.0f];
    
    self.userListTableView.delegate = self;
    self.userListTableView.dataSource = self;
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell   = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text     = self.registeredUsers[indexPath.row];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return self.registeredUsers.count;
}

- (void)updateTable:(NSArray *)registeringUser{
    self.registeredUsers =  [[NSMutableArray alloc] init];
        self.registeredUsers = [registeringUser mutableCopy];
    
    [self.userListTableView reloadData];
}

- (void) removeRegisteredUser:(NSString *)username{
    if ([self.registeredUsers containsObject:username]) {
       // NSMutableArray *newArray = [NSMutableArray arrayWithArray: self.registeredUsers ];
       // [self.registeredUsers removeObject: @"support"];
       // self.registeredUsers = newArray;
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   [self.delegate toTextInputViewCell:self shouldCallUser:self.registeredUsers[indexPath.row]];
}


- (IBAction)touchButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(toTextInputViewCell:shouldCallUser:)]) {
        [self.delegate toTextInputViewCell:self shouldCallUser:@"testEntry"];  //self.textField.text
    }
}

#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL isBackspace = [string isEqualToString:@""] && range.length == 1;
    NSString *text = [NSString stringWithFormat:@"%@%@", textField.text, string];
    if (isBackspace && text.length > 1) {
        text = [text substringWithRange:NSMakeRange(0, text.length-2)];
    }
    if (text.length >= 5) {
        [UIView animateWithDuration:0.3f animations:^{
            [self.errorLabelHeightConstraint setConstant:0.0f];
          //  [self.textFieldBorderView setBackgroundColor:[UIColor colorWithRed:66.0f/255.0f green:133.0f/255.0f blue:244.0f/255.0f alpha:1.0f]];
            [self.joinButton setBackgroundColor:[UIColor colorWithRed:66.0f/255.0f green:133.0f/255.0f blue:244.0f/255.0f alpha:1.0f]];
            [self.joinButton setEnabled:YES];
            [self layoutIfNeeded];
        }];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            [self.errorLabelHeightConstraint setConstant:40.0f];
          //  [self.textFieldBorderView setBackgroundColor:[UIColor colorWithRed:244.0f/255.0f green:67.0f/255.0f blue:54.0f/255.0f alpha:1.0f]];
            [self.joinButton setBackgroundColor:[UIColor colorWithWhite:100.0f/255.0f alpha:1.0f]];
            [self.joinButton setEnabled:NO];
            [self layoutIfNeeded];
        }];
    }
    return YES;
}

@end
