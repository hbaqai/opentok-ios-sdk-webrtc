//
//  ViewController.m
//  SampleApp
//
//  Created by Charley Robinson on 12/13/11.
//  Copyright (c) 2011 Tokbox, Inc. All rights reserved.
//

#import "ViewController.h"
#import "OpentokAPICredentials.h"

#define HEIGHT 480.0
#define WIDTH 640.0
#define WIDTH_TO_HEIGHT_RATIO WIDTH/HEIGHT
#define HEIGHT_TO_WIDTH_RATIO HEIGHT/WIDTH


@interface ViewController () <UITextFieldDelegate>
@property (nonatomic, strong) NSString *tokenId;
@property (nonatomic, strong) OTSession *session;
@property (nonatomic, strong) OTPublisher *publisher;
@property (nonatomic, strong) OTSubscriber *subscriber;
@property CGRect publisherRect;
@property CGRect subscriberRect;
@property (nonatomic, strong) OpentokApiHelper *helper;
@property (nonatomic, strong) UITextView *chatWindow;
@property (nonatomic, strong) UITextField *chatMessageField;
@property (nonatomic, strong) UIButton *sendChatButton;

@end

@implementation ViewController
@synthesize roomName = _roomName;
@synthesize p2pEnabled = _p2pEnabled;
@synthesize tokenId = _tokenId;
@synthesize session = _session;
@synthesize publisher = _publisher;
@synthesize subscriber = _subscriber;
@synthesize publisherRect = _publisherRect;
@synthesize subscriberRect = _subscriberRect;
@synthesize helper = _helper;
@synthesize chatWindow = _chatWindow;
@synthesize chatMessageField = _chatMessageField;
@synthesize sendChatButton = _sendChatButton;

// *** Fill the following variables using your own Project info from the Dashboard  ***
// ***                   https://dashboard.tokbox.com/projects                      ***
static NSString* const kApiKey = API_KEY;    // Replace with your OpenTok API key

static bool subscribeToSelf = NO; // Change to NO to subscribe to streams other than your own.

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //instantiate the OpenTokApiHelper and set self to be its delegate.
    //This ViewController must then implement the OpenTokApiHelperDelegate protocol.
    self.helper = [[OpentokApiHelper alloc] initWithApiKey:API_KEY];
    self.helper.delegate = self;
    
    //make a RESTful call to Tokbox for the session ID. It will be returned in a delagate method.
    [self.helper requestSessionAndTokenForRoom:self.roomName P2pEnabled:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    if(self.session){
        [self.session disconnect];
        self.session = nil;
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
    } else {
        return YES;
    }
}

- (void)updateSubscriber {
    for (NSString* streamId in self.session.streams) {
        OTStream* stream = [self.session.streams valueForKey:streamId];
        if (![stream.connection.connectionId isEqualToString: self.session.connection.connectionId]) {
            self.subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
            break;
        }
    }
}

-(CGRect)publisherRect{
    if(_publisherRect.size.height == 0.0 || _publisherRect.size.width == 0.0){
        CGFloat publisherHeight = self.view.bounds.size.height/6.0;
        CGFloat publisherWidth = publisherHeight * WIDTH_TO_HEIGHT_RATIO;
        _publisherRect = CGRectMake(self.view.bounds.size.width - (publisherWidth + 20.0), 20, publisherWidth, publisherHeight);
    }
    return _publisherRect;
}

-(void)setPublisherRect:(CGRect)publisherRect{
    _publisherRect = publisherRect;
}

-(CGRect)subscriberRect{
    if(_subscriberRect.size.height == 0.0 || _subscriberRect.size.width == 0.0){
        if(self.view.bounds.size.width * HEIGHT_TO_WIDTH_RATIO < self.view.bounds.size.height){
            _subscriberRect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width * HEIGHT_TO_WIDTH_RATIO);
        }
        else{
            _subscriberRect = CGRectMake(0, 0, self.view.bounds.size.height * WIDTH_TO_HEIGHT_RATIO, self.view.bounds.size.height);
        }
    }
    return _subscriberRect;
}

-(void)setSubscriberRect:(CGRect)subscriberRect{
    _subscriberRect = subscriberRect;
}

-(void)updateViewHierarchies{
    NSLog(@"updateViewHierarchies");
    if(self.subscriber){
        NSLog(@"with subscriber");
        [self.view addSubview:self.subscriber.view];
    }
    [self.view addSubview:self.publisher.view];
}

-(void)createChatBoxes{
    NSLog(@"createChatBoxes");
    
    //create chat window
    CGRect chatWindowRect = CGRectMake(0, self.subscriber.view.bounds.size.height, self.subscriber.view.bounds.size.width, 75);
    self.chatWindow = [[UITextView alloc] initWithFrame:chatWindowRect];
    self.chatWindow.editable = NO;
    self.chatWindow.layer.borderWidth = 2.0f;
    self.chatWindow.layer.borderColor = [[UIColor grayColor] CGColor];
    [self.view addSubview:self.chatWindow];
    
    //create send message window
    CGRect chatMessageFieldRect = CGRectMake(0, self.subscriber.view.bounds.size.height + 75, self.subscriber.view.bounds.size.width, 45);
    self.chatMessageField = [[UITextField alloc] initWithFrame:chatMessageFieldRect];
    self.chatMessageField.delegate = self;
    self.chatMessageField.placeholder = @"Enter a message";
    self.chatMessageField.backgroundColor = [UIColor lightGrayColor];
    self.chatMessageField.returnKeyType = UIReturnKeySend;
    [self.view addSubview:self.chatMessageField];
}

#pragma mark - OpenTok methods

- (void)doConnect
{
    NSString *token = self.tokenId;
    [self.session connectWithApiKey:kApiKey token:token];
}

- (void)doPublish
{
    self.publisher = [[OTPublisher alloc] initWithDelegate:self];
    [self.publisher setName:[[UIDevice currentDevice] name]];
    [self.session publish:self.publisher];
    [self.publisher.view setFrame:self.publisherRect];
    [self updateViewHierarchies];
}

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    [self initializeSignalHandler];
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString *sessionDisconnectLogMessage = [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", sessionDisconnectLogMessage);
}


- (void)session:(OTSession*)mySession didReceiveStream:(OTStream*)stream
{
    NSLog(@"session didReceiveStream (%@)", stream.streamId);
    
    // See the declaration of subscribeToSelf above.
    if ( (subscribeToSelf && [stream.connection.connectionId isEqualToString: self.session.connection.connectionId])
        ||
        (!subscribeToSelf && ![stream.connection.connectionId isEqualToString: self.session.connection.connectionId])
        ) {
        if (!self.subscriber) {
            self.subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
            [self.subscriber.view setFrame:self.subscriberRect];
            //create a text view and text field to type into
            [self createChatBoxes];
            [self updateViewHierarchies];
        }
    }
}

- (void)session:(OTSession*)session didDropStream:(OTStream*)stream{
    NSLog(@"session didDropStream (%@)", stream.streamId);
    NSLog(@"self.subscriber.stream.streamId (%@)", self.subscriber.stream.streamId);
    if (!subscribeToSelf
        && self.subscriber
        && [self.subscriber.stream.streamId isEqualToString: stream.streamId])
    {
        self.subscriber = nil;
        [self updateSubscriber];
    }
}

- (void)session:(OTSession *)session didCreateConnection:(OTConnection *)connection {
    NSLog(@"session didCreateConnection (%@)", connection.connectionId);
}

- (void) session:(OTSession *)session didDropConnection:(OTConnection *)connection {
    NSLog(@"session didDropConnection (%@)", connection.connectionId);
}

- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{
    NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
}

- (void)publisher:(OTPublisher*)publisher didFailWithError:(OTError*) error {
    NSLog(@"publisher didFailWithError %@", error);
    [self showAlert:[NSString stringWithFormat:@"There was an error publishing."]];
}

- (void)subscriber:(OTSubscriber*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
    [self showAlert:[NSString stringWithFormat:@"There was an error subscribing to stream %@", subscriber.stream.streamId]];
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
    NSLog(@"sessionDidFail");
    [self showAlert:[NSString stringWithFormat:@"There was an error connecting to session %@", session.sessionId]];
}

- (void)showAlert:(NSString*)string {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from video session"
                                                    message:string
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Signaling

-(void)sendMessage:(NSDictionary *)message{
    [self.session signalWithType:@"message" data:message completionHandler:^(NSError *error) {
        NSLog(@"message sent: %@", message);
    }];
}

-(void)initializeSignalHandler{
    NSLog(@"Signal handlers initialized");
    //set up handler for connect messages
    [_session receiveSignalType:@"message" withHandler:^(NSString *type, id data, OTConnection *fromConnection) {
        NSLog(@"Message from: %@", [data valueForKey:@"name"]);
        NSLog(@"text: %@", [data valueForKey:@"text"]);
        NSString *message = [NSString stringWithFormat:@"\n%@: %@",[data valueForKey:@"name"], [data valueForKey:@"text"]];
        self.chatWindow.text = [self.chatWindow.text stringByAppendingString:message];
        [self.chatWindow scrollRangeToVisible:NSMakeRange([self.chatWindow.text length], 0)];
    }];
}

#pragma mark - OpentokApiHelperDelegate
-(void)openTokApiHelper:(OpentokApiHelper *)openTokApiHelper returnedSessionId:(NSString *)sessionId andTokenId:(NSString *)tokenId error:(NSError *)error{
    NSLog(@"openTokApiHelper:resturnedSessionId Delegate Method");
    if(!error){
        //use the retrieved session ID to initialize the OTSession
        self.session = [[OTSession alloc] initWithSessionId:sessionId
                                                   delegate:self];
        self.tokenId = tokenId;
        [self doConnect];
    }
    else{
        NSLog(@"ERROR while obtaining session ID: %@", error);
    }
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    //send a signal message
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setValue:[[UIDevice currentDevice] name] forKey:@"name"];
    [data setValue:textField.text forKey:@"text"];
    [self sendMessage:data];
    
    textField.text = @"";
    return NO;
}

@end
