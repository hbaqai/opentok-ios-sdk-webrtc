//
//  ViewController.h
//  SampleApp
//
//  Created by Charley Robinson on 12/13/11.
//  Copyright (c) 2011 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Opentok/Opentok.h>
#import "OpentokApiHelper.h"

@interface ViewController : UIViewController <OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate, OpentokApiHelperDelegate>
@property (nonatomic, strong) NSString *roomName;
@property BOOL p2pEnabled;
- (void)doConnect;
- (void)doPublish;
- (void)showAlert:(NSString*)string;
@end
