# TwitterHelper
Twitter Helper Class to integrate Twitter signin and tweet feature easily.

If you haven’t created your Twitter project, create it by following steps on following URL - https://dev.twitter.com/twitter-kit/ios/configure

After creating project, add the Helper, STTwitter and MBProgressHUD class to your project. 

In your project, add URL type with unique Identifier and scheme and use it to match in the delegate method of your application

Call the notification with name "SetTwitterToken", which handles the functionality of helper class.

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url scheme] isEqualToString:@"twitterhelperdemo"])
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SetTwitterToken" object:[url query]];
    else
        return NO;
    return YES;
}

Atlast, replace your project’s Consumer key and consumer secret in the helper class.