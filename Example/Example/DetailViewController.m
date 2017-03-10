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
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)press:(id)sender {

    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[ARDAppClient class]] URLForResource:@"mscrtc" withExtension:@"bundle"]];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MSCWebRTC"
                                                         bundle:bundle];
//    UIViewController *testController = [storyboard instantiateInitialViewController];
    UIViewController *uvc = [storyboard instantiateViewControllerWithIdentifier:@"Video"];
    [self presentViewController:uvc animated:YES completion:nil];
}

@end
