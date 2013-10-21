//
//  OpentokApiHelper.h
//  NsurlHelloWorld
//
//  Created by Hashir Baqai on 9/9/13.
//  Copyright (c) 2013 Hashir Baqai. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OpentokApiHelper;

@protocol OpentokApiHelperDelegate <NSObject>
@required
//Once a request is made, this method returns a session ID
-(void)openTokApiHelper:(OpentokApiHelper *)openTokApiHelper returnedSessionId:(NSString *)sessionId error:(NSError *)error;
@end

@interface OpentokApiHelper : NSObject <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, weak) id <OpentokApiHelperDelegate> delegate;

//the designated initializer
-(OpentokApiHelper *)initWithApiKey:(NSString *)apiKey andSecret:(NSString *)apiSecret;
//requests a session ID from the Opentok server
-(void)requestSessionIdFromTokboxP2pEnabled:(BOOL)p2pEnabled;
//generate a token locally
-(NSString *)generateTokenIdForSession:(NSString *)sessionId;

@end
