//
//  OpentokRoomSelectorViewController.m
//  OpenTokHelloWorld
//
//  Created by Hashir Baqai on 10/21/13.
//
//

#import "OpentokRoomSelectorViewController.h"
#import "ViewController.h"

@interface OpentokRoomSelectorViewController ()

@end

@implementation OpentokRoomSelectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setRoomNameTextField:nil];
    [self setP2pEnabledSwitch:nil];
    [super viewDidUnload];
}
- (IBAction)joinRoomButton:(id)sender {
    NSLog(@"roomName: %@", self.roomNameTextField.text);
    if(!self.roomNameTextField.text || [self.roomNameTextField.text isEqualToString:@""]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Room Name Entered"
                                                        message:@"You must enter a room name to continue."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else [self performSegueWithIdentifier:@"StartSession" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [segue.destinationViewController setRoomName:self.roomNameTextField.text];
    [segue.destinationViewController setP2pEnabled:self.p2pEnabledSwitch.on];
}

@end
