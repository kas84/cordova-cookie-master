//
//  CDVCookieMaster.m
//
//
//  Created by Kristian Hristov on 12/16/14.
//
//

#import "CDVCookieMaster.h"
#import <WebKit/WebKit.h>


@implementation CDVCookieMaster

- (void)getCookieValue:(CDVInvokedUrlCommand*)command {
    __block CDVPluginResult* pluginResult = nil;
    NSString* urlString = [command.arguments objectAtIndex:0];
    __block NSString* cookieName = [command.arguments objectAtIndex:1];

    // Get the WKWebView instance from the cordova web view
    WKWebView *wkWebView = (WKWebView *)self.webView;

    // Get the HTTPCookieStore from the WKWebView
    WKHTTPCookieStore *cookieStore = wkWebView.configuration.websiteDataStore.httpCookieStore;

    if (urlString != nil) {
        // Get all cookies from the WKHTTPCookieStore
        [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * cookies) {
            __block NSString *cookieValue;

            for (NSHTTPCookie *cookie in cookies) {
                // Check if the cookie's name matches the one we're looking for
                if ([cookie.name isEqualToString:cookieName]) {
                    cookieValue = cookie.value;
                    break;  // Exit the loop once the cookie is found
                }
            }

            // Check if we found a cookie with the given name
            if (cookieValue != nil) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"cookieValue":cookieValue}];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No cookie found"];
            }

            // Return the result to the Cordova callback
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"URL was null"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


 - (void)setCookieValue:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* urlString = [command.arguments objectAtIndex:0];
    NSString* cookieName = [command.arguments objectAtIndex:1];
    NSString* cookieValue = [command.arguments objectAtIndex:2];

    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
    [cookieProperties setObject:cookieValue forKey:NSHTTPCookieValue];
    [cookieProperties setObject:urlString forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];

    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];

    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView* wkWebView = (WKWebView*) self.webView;

        if (@available(iOS 11.0, *)) {
            [wkWebView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:^{NSLog(@"Cookie set in WKWebView");}];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"WKWebView requires iOS 11+ in order to set the cookie"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

            return;
        }
    } else {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

        NSArray* cookies = [NSArray arrayWithObjects:cookie, nil];

        NSURL *url = [[NSURL alloc] initWithString:urlString];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:nil];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Set cookie executed"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearCookies:(CDVInvokedUrlCommand*)command
{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearCookie:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* urlString = [command.arguments objectAtIndex:0];
    NSString* cookieName = [command.arguments objectAtIndex:1];

    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
    [cookieProperties setObject:@"InvalidCookie" forKey:NSHTTPCookieValue];
    [cookieProperties setObject:urlString forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];

    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];

    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView* wkWebView = (WKWebView*) self.webView;

        if (@available(iOS 11.0, *)) {
            [wkWebView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:^{NSLog(@"Cookie cleared in WKWebView");}];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"WKWebView requires iOS 11+ in order to clear the cookie"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

            return;
        }
    } else {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

        NSArray* cookies = [NSArray arrayWithObjects:cookie, nil];

        NSURL *url = [[NSURL alloc] initWithString:urlString];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:nil];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Clear cookie executed"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
