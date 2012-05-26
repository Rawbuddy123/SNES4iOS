//
//  SaveStateSelectionViewController.m
//  SNES4iPad
//
//  Created by Yusef Napora on 5/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SNES4iOSAppDelegate.h"
#import "SaveStateSelectionViewController.h"
#import "EmulationViewController.h"
#import <UIKit/UITableView.h>

@implementation SaveStateSelectionViewController

@synthesize romFilter, selectedSavePath, selectedScreenshotPath, saveTableView, editButton, toolbar, saveFiles;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    self.saveFiles = [[NSMutableArray alloc] init];
    
    CGRect tableFrame = self.view.bounds;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [toolbar setHidden:YES];
        editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonPressed:)];
        self.navigationItem.rightBarButtonItem = editButton;
    } else {
        tableFrame.size.height -= 44;
        tableFrame.origin.y += 44;
    }
    
    saveTableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
	saveTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	saveTableView.dataSource = self;
	saveTableView.delegate = self;
	
	[self.view addSubview:saveTableView];
    
    //[self scanSaveDirectory];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *indexSaveFile = ([saveTableView indexPathForSelectedRow]) ? [[self.saveFiles objectAtIndex:[saveTableView indexPathForSelectedRow].row] objectForKey:@"title"] : @"";
    [self scanSaveDirectory];
    for (int i = 0; i < [self.saveFiles count]; i++ )
	{
        NSDictionary *dic = [self.saveFiles objectAtIndex:i];
        NSString *saveFile = [dic objectForKey:@"title"];
        
		if([saveFile isEqualToString:indexSaveFile]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [saveTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [saveTableView deselectRowAtIndexPath:indexPath animated:YES];
            continue;
        }
    }
    
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);//YES;
}

 
- (void) scanSaveDirectory
{
	if (!self.romFilter) {
		return;
	}
	
	
	NSMutableArray *saveArray = [[NSMutableArray alloc] init];
	NSString *saveDir;
	NSString *path = AppDelegate().saveDirectoryPath;
    NSLog(@"Save Directory: %@", path);
	if([[path substringWithRange:NSMakeRange([path length]-1,1)] compare:@"/"] == NSOrderedSame)
	{
		saveDir = path;
	}
	else
	{
		saveDir = [path stringByAppendingString:@"/"];
	}
	
	int i;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:saveDir error:nil];
	NSInteger entries = [dirContents count];
    
	for ( i = 0; i < entries; i++ ) 
	{
		if(([[dirContents objectAtIndex:i] length] < 4) ||
		   [[[dirContents objectAtIndex:i] substringWithRange:NSMakeRange([[dirContents objectAtIndex: i] length]-3,3)] caseInsensitiveCompare:@".sv"] != NSOrderedSame)
		{
			// Do nothing currently.
		}
		else
		{
			NSString* saveFile = [dirContents objectAtIndex:i];
			if (saveFile.length > romFilter.length) {
			    NSString *romComparison = [saveFile substringToIndex:[romFilter length]];
			    if (![romComparison isEqual:romFilter]) {
				    continue;
			    }
                
                NSString *saveFilePath = [AppDelegate().saveDirectoryPath stringByAppendingPathComponent:saveFile];
                NSDictionary *attr = [fileManager attributesOfItemAtPath:saveFilePath error:NULL];
                NSDate *saveDate = [attr objectForKey:NSFileModificationDate];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
                NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:saveFile, @"title", [dateFormatter stringFromDate:saveDate], @"date", nil];
                
			    [saveArray addObject:dic];
		    }
		}
	}
	
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	self.saveFiles = [saveArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
	
	[self.saveTableView reloadData];
}

- (IBAction) buttonPressed:(id)sender
{
	if (sender == editButton)
	{
		if (saveTableView.editing)
		{
			editButton.title = @"Edit";
            [saveTableView setEditing:NO animated:YES];
		} else {
			editButton.title = @"Done";
            [saveTableView setEditing:YES animated:YES];
		}
	}
}

- (void) deleteSaveAtIndex:(NSUInteger)saveIndex 
{
	NSString *savePath = [[AppDelegate() saveDirectoryPath] stringByAppendingPathComponent:
						  [[self.saveFiles objectAtIndex:saveIndex] objectForKey:@"title"]];
	NSString *screenshotPath = [savePath stringByAppendingPathExtension:@"png"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	if ([fileManager fileExistsAtPath:savePath]) {
		[fileManager removeItemAtPath:savePath error:&error];
	}
	if ([fileManager fileExistsAtPath:screenshotPath]) {
		[fileManager removeItemAtPath:screenshotPath error:&error];
	}
	
	if (!error) {
		NSMutableArray *mutableSaves = [self.saveFiles mutableCopy];

		[mutableSaves removeObjectAtIndex:saveIndex];
		self.saveFiles = [[NSArray alloc] initWithArray:mutableSaves];
		
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:saveIndex inSection:0];
		[saveTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if([self.saveFiles count] <= 0)
	{
		return 0;
	}
	
	return [self.saveFiles count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *reuseIdentifier = @"labelCell";
	UITableViewCell*      cell;	

	cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.adjustsFontSizeToFitWidth = YES;
		cell.textLabel.minimumFontSize = 9.0f;
		cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        cell.detailTextLabel.numberOfLines = 2;
		cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
		cell.detailTextLabel.minimumFontSize = 8.0f;
		cell.detailTextLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
	}
	
	cell.accessoryType = UITableViewCellAccessoryNone;				
	
	if([self.saveFiles count] <= 0)
	{
		cell.textLabel.text = @"";
		return cell;
	}
	
    NSDictionary *dic = [self.saveFiles objectAtIndex:indexPath.row];
	NSString *saveFile = [dic objectForKey:@"title"];
    NSString *saveFilePath = [AppDelegate().saveDirectoryPath stringByAppendingPathComponent:saveFile];
	cell.detailTextLabel.text = saveFile;
    cell.textLabel.text = [dic objectForKey:@"date"];
    
    NSString *screenshotPath = [saveFilePath stringByAppendingPathExtension:@"png"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotPath]) {
        UIImage *screenshotImage = [[UIImage alloc] initWithContentsOfFile:screenshotPath];
        cell.imageView.image = screenshotImage;
    }
    
	// Set up the cell
	return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}




// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self deleteSaveAtIndex:indexPath.row];
	}   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	if([self.saveFiles count] <= 0)
	{
		return;
	}
	
	NSString *listingsPath = AppDelegate().saveDirectoryPath;
    
    NSDictionary *dic = [self.saveFiles objectAtIndex:indexPath.row];
	NSString *saveFile = [dic objectForKey:@"title"];
	NSString *savePath = [listingsPath stringByAppendingPathComponent:saveFile];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *screenshotFile = [saveFile stringByAppendingPathExtension:@"png"];
	NSString *screenshotPath = [AppDelegate().saveDirectoryPath stringByAppendingPathComponent:screenshotFile];
	
	[self willChangeValueForKey:@"selectedScreenshotPath"];
	if (selectedScreenshotPath)
	{
		selectedScreenshotPath = nil;
	}
	
	NSLog(@"Looking for screenshot at %@", screenshotPath);
	if ([fileManager fileExistsAtPath:screenshotPath])
	{
		NSLog(@"Found screenshot at %@", screenshotPath);
		selectedScreenshotPath = screenshotPath;
	} 
	[self didChangeValueForKey:@"selectedScreenshotPath"];
	
	
	[self willChangeValueForKey:@"selectedSavePath"];
	selectedSavePath = savePath;
	[self didChangeValueForKey:@"selectedSavePath"];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        AppDelegate().snesControllerAppDelegate.controllerType = SNESControllerTypeLocal;
        [self presentViewController:AppDelegate().snesControllerViewController animated:NO completion:^{
            [AppDelegate().emulationViewController startWithRom:savePath];
            [AppDelegate() showEmulator:YES];
        }];
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}




@end

