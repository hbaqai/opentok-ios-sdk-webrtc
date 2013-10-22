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
-(void)openTokApiHelper:(OpentokApiHelper *)openTokApiHelper returnedSessionId:(NSString *)sessionId andTokenId:(NSString *)tokenId error:(NSError *)error;
@end

@interface OpentokApiHelper : NSObject <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, weak) id <OpentokApiHelperDelegate> delegate;

//the designated initializer
-(OpentokApiHelper *)initWithApiKey:(NSString *)apiKey;
//request a session and token from a server using Opentok server side SDK
-(void)requestSessionAndTokenForRoom:(NSString *)roomName P2pEnabled:(BOOL)p2pEnabled;

@end
