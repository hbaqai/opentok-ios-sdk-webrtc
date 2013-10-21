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

#define GENERATE_SESSION_ID_URL @"https://api.opentok.com/hl/session/create"

@interface OpentokApiHelper () <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableData *recievedData;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation OpentokApiHelper
@synthesize apiKey = _apiKey;
@synthesize secret = _secret;
@synthesize recievedData = _recievedData;
@synthesize currentElement = _currentElement;
@synthesize delegate = _delegate;
@synthesize connection = _connection;

-(OpentokApiHelper *)initWithApiKey:(NSString *)apiKey andSecret:(NSString *)apiSecret{
    self = [super init];
    if (self) {
        self.apiKey = apiKey;
        self.secret = apiSecret;
    }
    return self;
}

-(void)requestSessionIdFromTokboxP2pEnabled:(BOOL)p2pEnabled{
    //if p2pEnabled
    NSString *p2pEnabledParameter = @"enabled";
    if(!p2pEnabled) p2pEnabledParameter = @"disabled";
    
    //set up the request
    NSString *requestURL = @"https://api.opentok.com/hl/session/create";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    
    //headers
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSString *apiKeyAndSecret = [NSString stringWithFormat:@"%@:%@",self.apiKey,self.secret];
    [request setValue:apiKeyAndSecret forHTTPHeaderField:@"X-TB-PARTNER-AUTH"];
    
    //post body
    NSString *postBody =[NSString stringWithFormat:@"p2p.preference=%@", p2pEnabledParameter];
    NSData *postData = [postBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [request setHTTPBody:postData];
    
    //set a connection with the created request above
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

-(NSString *)generateTokenIdForSession:(NSString *)sessionId{
    /*
     Fields required to create a token:
     sessionId - obtained by making a post request to the server
     CreateTime - unix time in seconds (integers)
     expireTime - unix time in seconds. We will set to 24 hours (86400 seconds) from today. In this case it will be create_time + 86400
     role - we will use 'publisher'. If we want the user to be able to record the session and force others to disconnect, put ‘moderator’ here
     connectionData - This is just data. We can put in the user name
     nonce - a random number generated using ar4random % 99999
     */
    
    //crete time is right now
    int createTime = [[[NSDate alloc] init] timeIntervalSince1970];
    //expire time is 24 hours from now
    int expireTime = createTime + (24 * 60 * 60);
    //we set the role as publisher
    NSString *role = @"publisher";
    //connection data is just some data. We will use my name for now
    NSString *connectionData = @"hashir";
    //noonce is just a random number
    int nonce = arc4random() % 99999;
    
    NSLog(@"generateTokenIdForSession Method Executed");
    
    if(self.apiKey && sessionId && ![sessionId isEqualToString:@""]){
        NSLog(@"sessionId: %@", sessionId);
        NSLog(@"createTime: %i",createTime);
        NSLog(@"expireTime: %i",expireTime);
        NSLog(@"role: %@", role);
        NSLog(@"connectionData: %@", connectionData);
        NSLog(@"noonce: %i\n\n", nonce);
    
        NSString *dataString = [NSString stringWithFormat:@"session_id=%@&create_time=%i&expire_time=%i&role=%@&connection_data=%@&nonce=%i", sessionId, createTime, expireTime, role, connectionData, nonce];
        NSLog(@"dataString: %@\n\n", dataString);
    
        NSString *hmac = [self hmacSha1AsString:dataString];
        NSLog(@"formattedHmac: %@\n\n", hmac);
    
        NSString *precoded = [NSString stringWithFormat:@"partner_id=%@&sig=%@:%@", self.apiKey, hmac, dataString];
        NSLog(@"precoded: %@\n\n",precoded);
  
        //now base64 encode it
        NSString *base64Encoded = [precoded base64EncodedString];
        NSLog(@"base64Encoded: %@\n\n", base64Encoded);

        //finally, add add T1== before this to get our final result
        NSString *result = [NSString stringWithFormat:@"T1==%@",base64Encoded];
        NSLog(@"result: %@\n\n", result);
    
        return result;
    }
    else return nil;
}

-(NSString *)hmacSha1AsString:(NSString *)stringToConvert{
    if(self.secret){
        NSString *hashingKey = self.secret;
        NSString *data = stringToConvert;

        const char *cKey  = [hashingKey cStringUsingEncoding:NSASCIIStringEncoding];
        const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];

        unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

        CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

        NSData *convertedString = [[NSData alloc] initWithBytes:cHMAC
                                              length:sizeof(cHMAC)];

        //replace any spaces in the string
        NSString *almostFormatedConvertedString = [[[convertedString description] stringByReplacingOccurrencesOfString:@" " withString:@""] substringFromIndex:1];
        NSString *formattedConvertedString = [almostFormatedConvertedString substringToIndex:(almostFormatedConvertedString.length-1)];

        return formattedConvertedString;
    }
    else return nil;
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
static NSString *session_id = @"session_id";

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                        qualifiedName:(NSString *)qName
                                        attributes:(NSDictionary *)attributeDict{
    //NSLog(@"parser:didStartElement: %@", elementName);
    self.currentElement = elementName;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    //NSLog(@"parser:foundCharacters: %@",string);
    if([self.currentElement isEqualToString:session_id]){
        NSLog(@"%@ is: %@", self.currentElement, string);
        [self.delegate openTokApiHelper:self returnedSessionId:string error:nil];
    }
}


@end
