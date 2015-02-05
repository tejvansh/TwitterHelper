//
//  ViewController.m
//  TwitterHelperDemo
//
//  Created by TejvanshSingh Chhabra on 02/02/15.
//  Copyright (c) 2015 TejvanshSingh Chhabra. All rights reserved.
//

#import "ViewController.h"
#import "TwitterHelper.h"

@implementation ViewController
{
    IBOutlet UITextField *textFieldTweet;
}


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnSignIn:(id)sender {
    [[TwitterHelper sharedInstance] loginWithController:self andCompletion: ^(BOOL success, id result, NSError *error) {
        NSLog(@"User Details : %@", [TwitterHelper sharedInstance].userInfo);
    }];
}

- (IBAction)btnSignOut:(id)sender {
    [[TwitterHelper sharedInstance] logout];
}

- (IBAction)btnPost:(id)sender {
    [textFieldTweet resignFirstResponder];
    [[TwitterHelper sharedInstance] tweet:textFieldTweet.text fromController:self withCompletion:nil];
}

@end
