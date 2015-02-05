//
//  TwitterHelper.h
//  Twitter Helper
//
//  Created by TejvanshSingh Chhabra on 5/21/14.
//  Copyright (c) 2014 MAC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Foundation/Foundation.h>

#import "STTwitter.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"

@interface TwitterHelper : NSObject <UIActionSheetDelegate>

	typedef void (^TweetRequestBlock)(BOOL success, id result, NSError *error);

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) NSArray *iOSAccounts;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, strong) STTwitterAPI *twitter;
@property (nonatomic, readwrite, copy) TweetRequestBlock completionBlock;

+ (instancetype)sharedInstance;

#pragma mark - Public Methods

- (void)loginWithController:(UIViewController *)controller andCompletion:(TweetRequestBlock)completionHandler;
- (void)tweet:(NSString *)text fromController:(UIViewController *)viewController withCompletion:(TweetRequestBlock)completionHandler;
- (void)getTimelineWithCompletion:(TweetRequestBlock)completionHandler;
- (void)logout;

@end
