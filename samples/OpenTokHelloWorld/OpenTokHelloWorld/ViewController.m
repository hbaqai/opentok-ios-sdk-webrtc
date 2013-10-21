//
//  ViewController.m
//  SampleApp
//
//  Created by Charley Robinson on 12/13/11.
//  Copyright (c) 2011 Tokbox, Inc. All rights reserved.
//

#import "ViewController.h"

#define HEIGHT 480.0
#define WIDTH 640.0
#define WIDTH_TO_HEIGHT_RATIO WIDTH/HEIGHT
#define HEIGHT_TO_WIDTH_RATIO HEIGHT/WIDTH


@interface ViewController ()
@property (nonatomic, strong) OTSession *session;
@property (nonatomic, strong) OTPublisher *publisher;
@property (nonatomic, strong) OTSubscriber *subscriber;
@property CGRect publisherRect;
@property CGRect subscriberRect;

@end

@implementation ViewController
@synthesize session = _session;
@synthesize publisher = _publisher;
@synthesize subscriber = _subscriber;
@synthesize publisherRect = _publisherRect;
@synthesize subscriberRect = _subscriberRect;

// *** Fill the following variables using your own Project info from the Dashboard  ***
// ***                   https://dashboard.tokbox.com/projects                      ***
static NSString* const kApiKey = @"";    // Replace with your OpenTok API key
static NSString* const kSessionId = @""; // Replace with your generated session ID
static NSString* const kToken = @"";     // Replace with your generated token (use the Dashboard or an OpenTok server-side library)

static bool subscribeToSelf = YES; // Change to NO to subscribe to streams other than your own.

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.session = [[OTSession alloc] initWithSessionId:kSessionId
                                               delegate:self];
    [self doConnect];
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

#pragma mark - OpenTok methods

- (void)doConnect
{
    [self.session connectWithApiKey:kApiKey token:kToken];
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
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage = [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    [self showAlert:alertMessage];
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

@end
