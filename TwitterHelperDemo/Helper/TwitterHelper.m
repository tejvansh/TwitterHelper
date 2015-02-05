//
//  TwitterHelper.m
//  Twitter Helper
//
//  Created by TejvanshSingh Chhabra on 5/21/14.
//  Copyright (c) 2014 MAC. All rights reserved.
//

#import "TwitterHelper.h"

#define appDel ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define kLOADING        @"Loading" // String you want to show with Indicator
#define kCallBackURL    @"TwitterHelperDemo://twitter_access_tokens/" // Your CallBack URL created while developing twitter developer account
#define kConsumerKey    @"WRYUGfjrBwR3OeCChHXVFRzN7" // Your Consumer Key created while developing twitter developer account
#define kConsumerSecret @"oZMOGC2Cqki06XK0pQMSZStOg636H1IfzlQ7nj9JrMImOBK9wA" // Your Consumer Secret created while developing twitter developer account

@implementation TwitterHelper

#pragma mark - Singleton Methods

+ (instancetype)sharedInstance {
	static TwitterHelper *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    sharedInstance = [[super allocWithZone:NULL] init];
	    [sharedInstance initialize];
	});
	return sharedInstance;
}

- (void)initialize {
	if (self.accountStore == nil)
		self.accountStore = [[ACAccountStore alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTokenAndVerifier:) name:@"SetTwitterToken" object:nil];
}

#pragma mark - Twitter Methods

- (void)loginWithController:(UIViewController *)controller andCompletion:(TweetRequestBlock)completionHandler {
    if (self.twitter == nil) {
        [self showGlobalHUDWithTitle:kLOADING];
        
        self.completionBlock = completionHandler;
        
        ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        ACAccountStoreRequestAccessCompletionHandler accountStoreRequestCompletionHandler = ^(BOOL granted, NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                if (granted == NO || error) {
                    [self hideGlobalHUD];
                    if (self.completionBlock) {
                        self.completionBlock(NO, nil, error);
                        self.completionBlock = nil;
                    }
                }
                else {
                    self.iOSAccounts = [self.accountStore accountsWithAccountType:accountType];
                    if ([self.iOSAccounts count] == 0) {
                        [self loginUsingSTTwitter];
                    }
                    else if ([self.iOSAccounts count] == 1) {
                        [self loginWithiOSAccount:[self.iOSAccounts lastObject]];
                    }
                    else {
                        UIActionSheet *actionSheetAccount = [[UIActionSheet alloc] initWithTitle:@"Select an account:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
                        for (ACAccount * account in self.iOSAccounts)
                            [actionSheetAccount addButtonWithTitle:[NSString stringWithFormat:@"@%@", account.username]];
                        
                        [actionSheetAccount showInView:controller.view.window];
                    }
                }
            }];
        };
        
#if TARGET_OS_IPHONE &&  (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0)
        if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_6_0)
            [self.accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:accountStoreRequestCompletionHandler];
        else
            [self.accountStore requestAccessToAccountsWithType:accountType options:NULL completion:accountStoreRequestCompletionHandler];
#else
        [self.accountStore requestAccessToAccountsWithType:accountType options:NULL completion:accountStoreRequestCompletionHandler];
#endif
    }
    else if (self.completionBlock) {
        self.completionBlock(YES, self.userInfo, nil);
        self.completionBlock = nil;
    }
}

- (void)loginWithiOSAccount:(ACAccount *)account {
	self.twitter = [STTwitterAPI twitterAPIOSWithAccount:account];
	[self.twitter verifyCredentialsWithSuccessBlock: ^(NSString *username) {
	    self.twitter.userName = username;
	    [self.twitter getUserInformationFor:username successBlock: ^(NSDictionary *user) {
	        //NSLog(@"-- userInfo: %@", user);
	        self.userInfo = user;
	        [self hideGlobalHUD];
	        if (self.completionBlock) {
	            self.completionBlock(YES, user, nil);
	            self.completionBlock = nil;
			}
		} errorBlock: ^(NSError *error) {
	        NSLog(@"-- %@", [error localizedDescription]);
	        [self hideGlobalHUD];
	        if (self.completionBlock) {
	            self.completionBlock(NO, nil, error);
	            self.completionBlock = nil;
			}
		}];
	} errorBlock: ^(NSError *error) {
	    NSLog(@"-- error: %@", error);
	    [self hideGlobalHUD];
	    if (self.completionBlock) {
	        self.completionBlock(NO, nil, error);
	        self.completionBlock = nil;
		}
	}];
}

- (void)loginUsingSTTwitter {
	self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:kConsumerKey consumerSecret:kConsumerSecret];
	[self.twitter postTokenRequest: ^(NSURL *url, NSString *oauthToken) {
	    [[UIApplication sharedApplication] openURL:url];
	} authenticateInsteadOfAuthorize:NO forceLogin:@(YES) screenName:nil oauthCallback:kCallBackURL errorBlock: ^(NSError *error) {
	    NSLog(@"-- error: %@", error);
	    [self hideGlobalHUD];
	    if (self.completionBlock) {
	        self.completionBlock(NO, nil, error);
	        self.completionBlock = nil;
		}
	}];
}

- (void)tweet:(NSString *)text fromController:(UIViewController *)viewController withCompletion:(TweetRequestBlock)completionHandler {
    [self loginWithController:viewController andCompletion:^(BOOL success, id result, NSError *error) {
        if(success) {
            [self.twitter postStatusUpdate:text inReplyToStatusID:nil latitude:nil longitude:nil placeID:nil displayCoordinates:nil trimUser:nil successBlock: ^(NSDictionary *status) {
                if(success)
                {
                    if (self.completionBlock) {
                        self.completionBlock(YES, status, error);
                        self.completionBlock = nil;
                }
                }
            } errorBlock: ^(NSError *error) {
                NSLog(@"-- error: %@", error);
                [self hideGlobalHUD];
                if (self.completionBlock) {
                    self.completionBlock(NO, nil, error);
                    self.completionBlock = nil;
                }
            }];
        }
    }];
}

- (void)logout {
	if (self.twitter)
		self.twitter = nil;
}

- (void)getTimelineWithCompletion:(TweetRequestBlock)completionHandler {
	[self.twitter getHomeTimelineSinceID:nil count:20 successBlock: ^(NSArray *statuses) {
	    NSLog(@"-- statuses: %@", statuses);
	    [self hideGlobalHUD];
	    if (self.completionBlock) {
	        self.completionBlock(YES, statuses, nil);
	        self.completionBlock = nil;
		}
	} errorBlock: ^(NSError *error) {
	    NSLog(@"-- error: %@", error);
	    [self hideGlobalHUD];
	    if (self.completionBlock) {
	        self.completionBlock(NO, nil, error);
	        self.completionBlock = nil;
		}
	}];
}

- (void)setOAuthToken:(NSString *)token oauthVerifier:(NSString *)verifier {
	[self.twitter postAccessTokenRequestWithPIN:verifier successBlock: ^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
	    //NSLog(@"-- screenName: %@", screenName);
	    self.twitter.userName = screenName;
	    [self.twitter getUserInformationFor:screenName successBlock: ^(NSDictionary *user) {
	        //NSLog(@"-- userInfo: %@", user);
	        self.userInfo = user;
	        [self hideGlobalHUD];
	        if (self.completionBlock) {
	            self.completionBlock(YES, user, nil);
	            self.completionBlock = nil;
			}
		} errorBlock: ^(NSError *error) {
	        NSLog(@"-- %@", [error localizedDescription]);
	        [self hideGlobalHUD];
	        if (self.completionBlock) {
	            self.completionBlock(NO, nil, error);
	            self.completionBlock = nil;
			}
		}];


	    /*
	       At this point, the user can use the API and you can read his access tokens with:

	       _twitter.oauthAccessToken;
	       _twitter.oauthAccessTokenSecret;

	       You can store these tokens (in user default, or in keychain) so that the user doesn't need to authenticate again on next launches.

	       Next time, just instanciate STTwitter with the class method:

	       +[STTwitterAPI twitterAPIWithOAuthConsumerKey:consumerSecret:oauthToken:oauthTokenSecret:]

	       Don't forget to call the -[STTwitter verifyCredentialsWithSuccessBlock:errorBlock:] after that.
	     */
	} errorBlock: ^(NSError *error) {
	    NSLog(@"-- %@", [error localizedDescription]);
	    [self hideGlobalHUD];
	    if (self.completionBlock) {
	        self.completionBlock(NO, nil, error);
	        self.completionBlock = nil;
		}
	}];
}

- (void)setTokenAndVerifier:(NSNotification *)notification {
	NSDictionary *d = [self parametersDictionaryFromQueryString:notification.object];
	NSString *token = d[@"oauth_token"];
	NSString *verifier = d[@"oauth_verifier"];
	[self setOAuthToken:token oauthVerifier:verifier];
}

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString {
	NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
	NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
	for (NSString *s in queryComponents) {
		NSArray *pair = [s componentsSeparatedByString:@"="];
		if ([pair count] != 2)
			continue;

		NSString *key = pair[0];
		NSString *value = pair[1];
		mutDict[key] = value;
	}
	return mutDict;
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != [actionSheet cancelButtonIndex]) {
		NSUInteger accountIndex = buttonIndex - 1;
		ACAccount *account = [self.iOSAccounts objectAtIndex:accountIndex];
		[self loginWithiOSAccount:account];
	}
}

#pragma mark - Global Indicator Methods

/**
 *  This method displays MBProgressHUD on top of window to perform synchronous tasks.
 *
 *  @param title Title of the indicator you want to display while performing any task.
 */
- (void)showGlobalHUDWithTitle:(NSString *)title {
	[self hideGlobalHUD];
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:(UIView *)appDel.window animated:YES];
	hud.labelText = title;
}

/**
 *  Method will hide any hud currently visible on the window.
 */
- (void)hideGlobalHUD {
	[MBProgressHUD hideAllHUDsForView:(UIView *)appDel.window animated:YES];
}

@end
