//
//  OpentokApiHelper.m
//  NsurlHelloWorld
//
//  Created by Hashir Baqai on 9/9/13.
//  Copyright (c) 2013 Hashir Baqai. All rights reserved.
//

#import "OpentokApiHelper.h"
#import <CommonCrypto/CommonHMAC.h>
#import "Base64.h"

//enter the URL where your RESTful resource is located
#define OBTAIN_SESSION_URL @""

@interface OpentokApiHelper () <NSXMLParserDelegate>
@property (nonatomic, strong) NSString *sessionIdReturned;
@property (nonatomic, strong) NSMutableData *recievedData;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation OpentokApiHelper
@synthesize sessionIdReturned = _sessionIdReturned;
@synthesize apiKey = _apiKey;
@synthesize recievedData = _recievedData;
@synthesize currentElement = _currentElement;
@synthesize delegate = _delegate;
@synthesize connection = _connection;

-(OpentokApiHelper *)initWithApiKey:(NSString *)apiKey{
    self = [super init];
    if (self) self.apiKey = apiKey;
    return self;
}

-(void)requestSessionAndTokenForRoom:(NSString *)roomName P2pEnabled:(BOOL)p2pEnabled{
    //if p2pEnabled
    NSString *p2pEnabledParameter = @"enabled";
    if(!p2pEnabled) p2pEnabledParameter = @"disabled";
    
    //set up the request
    NSString *requestURL = OBTAIN_SESSION_URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    //headers
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    NSString *postBody =[NSString stringWithFormat:@"roomname=%@", roomName];
    NSData *postData = [postBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [request setHTTPBody:postData];
    
    //set a connection with the created request above
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark - NSURlConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"connection:didReceiveResponse delegate method executed. Contents: %@", response);
    [self.recievedData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSLog(@"Connection did recieve data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    //pull out the session id from the response
    NSMutableData *xmlData = [data mutableCopy];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
    xmlParser.delegate = self;
    [xmlParser parse];
    //the sessionId will be returned in a delegate method callback. Namely, the parser:foundCharacters: delegate method
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"An error occoured");
    NSLog(@"Error: %@", error);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"Connection finished loading");
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
    return nil;
}

#pragma mark NSXMLParserDelegate

//elements to obtain data for
static NSString *sessionId = @"sessionId";
static NSString *tokenId = @"tokenId";

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                        qualifiedName:(NSString *)qName
                                        attributes:(NSDictionary *)attributeDict{
    //NSLog(@"parser:didStartElement: %@", elementName);
    self.currentElement = elementName;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    //NSLog(@"parser:foundCharacters: %@",string);
    if([self.currentElement isEqualToString:sessionId]){
        NSLog(@"%@ is: %@", self.currentElement, string);
        self.sessionIdReturned = string;
    }
    else if([self.currentElement isEqualToString:tokenId]){
        NSLog(@"%@ is: %@", self.currentElement, string);
        [self.delegate openTokApiHelper:self returnedSessionId:self.sessionIdReturned andTokenId:string error:nil];
    }
    
}

@end
