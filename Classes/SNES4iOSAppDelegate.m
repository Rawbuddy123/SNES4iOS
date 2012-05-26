//
//  SNES4iPadAppDelegate.m
//  SNES4iPad
//
//  Created by Yusef Napora on 5/10/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "SNES4iOSAppDelegate.h"

#import "EmulationViewController.h"
#import "RomSelectionViewController.h"
#import "RomDetailViewController.h"
#import "SettingsViewController.h"
#import "ControlPadConnectViewController.h"
#import "ControlPadManager.h"
#import "WebBrowserViewController.h"

SNES4iOSAppDelegate *AppDelegate()
{
	return (SNES4iOSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@implementation SNES4iOSAppDelegate

@synthesize window, splitViewController, romSelectionViewController, romDetailViewController, settingsViewController;
@synthesize controlPadConnectViewController, controlPadManager;
@synthesize romDirectoryPath, saveDirectoryPath, snapshotDirectoryPath;
@synthesize emulationViewController, webViewController, webNavController;
@synthesize tabBarController;
@synthesize snesControllerAppDelegate, snesControllerViewController;
@synthesize sramDirectoryPath;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    //[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
	settingsViewController = [[SettingsViewController alloc] init];
	// access the view property to force it to load
	settingsViewController.view = settingsViewController.view;
	
	controlPadConnectViewController = [[ControlPadConnectViewController alloc] init];
	controlPadManager = [[ControlPadManager alloc] init];
    
	NSString *documentsPath = [SNES4iOSAppDelegate applicationDocumentsDirectory];
    //	romDirectoryPath = [[documentsPath stringByAppendingPathComponent:@"ROMs/SNES/"] retain];
	self.romDirectoryPath = [documentsPath copy];
	self.saveDirectoryPath = [romDirectoryPath stringByAppendingPathComponent:@"saves"];
	self.snapshotDirectoryPath = [saveDirectoryPath stringByAppendingPathComponent:@"snapshots"];
    self.sramDirectoryPath = [self.romDirectoryPath stringByAppendingPathComponent:@"sram"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager createDirectoryAtPath:saveDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:snapshotDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:self.sramDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    //Apple says its better to attempt to create the directories and accept an error than to manually check if they exist.
    
	// Make the main emulator view controller
	emulationViewController = [[EmulationViewController alloc] init];
	emulationViewController.view.hidden = YES;
    emulationViewController.view.userInteractionEnabled = NO;
	
	// Make the web browser view controller
	// And put it in a navigation controller with back/forward buttons
	webViewController = [[WebBrowserViewController alloc] initWithNibName:@"WebBrowserViewController" bundle:nil];
	webNavController = [[UINavigationController alloc] initWithRootViewController:webViewController];
	webNavController.navigationBar.barStyle = UIBarStyleBlack;
    
    snesControllerViewController = [[SNESControllerViewController alloc] initWithNibName:@"SNESControllerViewController" bundle:nil];
    snesControllerViewController.wantsFullScreenLayout = YES;
    
    snesControllerAppDelegate = [[SNESControllerAppDelegate alloc] init];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        self.romSelectionViewController = [[RomSelectionViewController alloc] initWithNibName:@"RomSelectionViewController" bundle:nil];
        self.romSelectionViewController.title = @"ROMs";
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *controllerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Controller"] style:UIBarButtonItemStylePlain target:self.romSelectionViewController action:@selector(loadSNESController)];
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self.settingsViewController action:@selector(showSettings)];
        self.romSelectionViewController.toolbarItems = [NSArray arrayWithObjects:controllerButton, flexibleSpace, settingsButton, nil];
        
        UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.romSelectionViewController];
        masterNavigationController.toolbarHidden = NO;
        self.window.rootViewController = masterNavigationController;
    } else {
        self.window.rootViewController = self.splitViewController;
        emulationViewController.view.userInteractionEnabled = YES;
    }
    [self.window makeKeyAndVisible];
	
    
	// Add the split view controller's view to the window and display.
    //[window addSubview:splitViewController.view];
	
	// Add the emulation view in its hidden state.
    
    emulationViewController.view.hidden = NO;
	
    [window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Save data if appropriate
}

- (void) showEmulator:(BOOL)showOrHide
{
	if (showOrHide) {
        [self.snesControllerViewController.view insertSubview:self.emulationViewController.view atIndex:0];
        self.splitViewController.view.hidden = YES;
        self.emulationViewController.view.hidden = NO;
        [self.emulationViewController setLandscapeRight];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	} else {
        UIViewController *presentedViewController = AppDelegate().snesControllerViewController;
        if (ControllerAppDelegate().controllerType == SNESControllerTypeWireless) {
            presentedViewController = AppDelegate().emulationViewController;
        }
        UIViewController *parentViewController = [presentedViewController parentViewController];
        if ([presentedViewController respondsToSelector:@selector(presentingViewController)]) {
            parentViewController = [presentedViewController presentingViewController];//Fixes iOS 5 bug
        }
        [parentViewController dismissModalViewControllerAnimated:NO];
        
        self.emulationViewController.view.hidden = YES;
        if (self.emulationViewController.view.superview != nil) {
            [self.emulationViewController.view removeFromSuperview];
        }
        self.splitViewController.view.hidden = NO;
        
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        UIView *view = self.window.rootViewController.view;
        int statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        [view setFrame:CGRectMake(0.0,statusBarHeight,view.bounds.size.width,view.bounds.size.height - statusBarHeight)];
	}
}

+ (NSString *) applicationDocumentsDirectory 
{    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark -
#pragma mark Memory management



@end

