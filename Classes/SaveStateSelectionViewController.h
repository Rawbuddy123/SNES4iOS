//
//  SaveStateSelectionViewController.h
//  SNES4iPad
//
//  Created by Yusef Napora on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SaveStateSelectionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	NSArray*         saveFiles;
	
	NSString *romFilter;
	NSString *selectedSavePath;
	NSString *selectedScreenshotPath;
	
	UIBarButtonItem *editButton;
    UIToolbar *toolbar;

	UITableView *saveTableView;
}

@property (nonatomic, copy) NSString *romFilter;
@property (nonatomic, copy) NSString *selectedSavePath;
@property (nonatomic, copy) NSString *selectedScreenshotPath;
@property (nonatomic, strong) IBOutlet UITableView *saveTableView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) NSArray *saveFiles;

- (void) scanSaveDirectory;
- (IBAction) buttonPressed:(id)sender;
- (void) deleteSaveAtIndex:(NSUInteger)saveIndex;
@end
