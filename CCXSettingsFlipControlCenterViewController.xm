#import "CCXSettingsPageTableViewController.h"
#import "CCXSettingsTableViewCell.h"
#import "CCXSettingsFlipControlCenterViewController.h"
#include <notify.h>

%subclass CCXSettingsFlipControlCenterViewController : UITableViewController
%property (nonatomic, retain) _UIVisualEffectLayerConfig *primaryEffectConfig;
%property (nonatomic, retain) NSBundle *templateBundle;
%property (nonatomic, retain) NSString *enabledKey;
%property (nonatomic, retain) NSMutableArray *enabledIdentifiers;
%property (nonatomic, retain) NSString *disabledKey;
%property (nonatomic, retain) NSMutableArray *disabledIdentifiers;
%property (nonatomic, retain) NSArray *allSwitches;
%property (nonatomic, retain) NSString *settingsFile;
%property (nonatomic, retain) NSString *preferencesApplicationID;
%property (nonatomic, retain) NSString *notificationName;
%property (nonatomic, retain) NSString *enabledSectionName;
%property (nonatomic, retain) NSString *disabledSectionName;
%property (nonatomic, retain) NSMutableArray *defaultEnabledIdentifiers;
%property (nonatomic, retain) NSMutableArray *defaultDisabledIdentifiers;

- (id)init {
	self = [self initWithStyle:UITableViewStyleGrouped];
	return self;
}
- (void)viewDidLoad {
    %orig;
   // [self.tableView setEditing:YES animated:NO];
    [self.tableView registerClass:[CCXSettingsTableViewCell class] forCellReuseIdentifier:@"Cell"];

     CCUIControlCenterVisualEffect *effect = [NSClassFromString(@"CCUIControlCenterVisualEffect")  _primaryRegularTextOnPlatterEffect];
    _UIVisualEffectConfig *effectConfig = [effect effectConfig];
   	self.primaryEffectConfig = effectConfig.contentConfig;

    self.view.backgroundColor = nil;

	NSDictionary *settings = nil;

	if (self.settingsFile) {
		if (self.preferencesApplicationID) {
			CFPreferencesAppSynchronize((__bridge CFStringRef)self.preferencesApplicationID);
			CFArrayRef keyList = CFPreferencesCopyKeyList((__bridge CFStringRef)self.preferencesApplicationID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
			if (keyList) {
				settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (__bridge CFStringRef)self.preferencesApplicationID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost));
			}
		} else {
			settings = [NSDictionary dictionaryWithContentsOfFile:self.settingsFile];
		}
	}

	NSArray *originalEnabled = [settings objectForKey:self.enabledKey];
	self.enabledIdentifiers = [originalEnabled mutableCopy];
	
	NSArray *originalDisabled = [settings objectForKey:self.disabledKey];
	self.disabledIdentifiers = [originalDisabled mutableCopy];
	
	self.allSwitches = ((FSSwitchPanel *)[NSClassFromString(@"FSSwitchPanel") sharedPanel]).sortedSwitchIdentifiers;
	NSMutableArray *allIdentifiers = [self.allSwitches mutableCopy];

	if (originalEnabled == nil) {
		originalEnabled = [self.defaultEnabledIdentifiers copy];
	}

	if (originalDisabled == nil) {
		originalDisabled = [self.defaultDisabledIdentifiers copy];
	}
	for  (NSString *identifier in originalEnabled) {
		if ([allIdentifiers containsObject:identifier]) {
			[allIdentifiers removeObject:identifier];
			[self.disabledIdentifiers removeObject:identifier];
		} else {
			[self.enabledIdentifiers removeObject:identifier];
		}
	}

	for (NSString *identifier in originalDisabled) {
		if ([allIdentifiers containsObject:identifier]) {
			[allIdentifiers removeObject:identifier];
		} else {
			[self.disabledIdentifiers removeObject:identifier];
		}
	}

	NSMutableArray *arrayToAddNewIdentifiers = self.disabledIdentifiers;
	for (NSString *identifier in allIdentifiers) {
		[arrayToAddNewIdentifiers addObject:identifier];
	}

	[(UITableView *)self.view setEditing: YES animated: YES];
	// CGFloat dummyViewHeight = 36;
	// UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, dummyViewHeight)];
	// self.tableView.tableHeaderView = dummyView;
	// self.tableView.contentInset = UIEdgeInsetsMake(-dummyViewHeight, 0, 0, 0);
	[self.tableView setSeparatorColor:[UIColor colorWithWhite:0 alpha:0.15]];
	self.tableView.allowsSelectionDuringEditing = NO;
}

-(void)viewDidLayoutSubviews
{
    %orig;
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}


#pragma mark - Table view data source

%new
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

%new
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self arrayForSection:section] count];
}

%new
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    CCXSettingsTableViewCell *cell = (CCXSettingsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[CCXSettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    FSSwitchPanel *panel = (FSSwitchPanel *)[NSClassFromString(@"FSSwitchPanel") sharedPanel];
	NSString *switchIdentifier = [[self arrayForSection:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = [panel titleForSwitchIdentifier:switchIdentifier];
	cell.imageView.image = [[panel imageOfSwitchState:FSSwitchStateIndeterminate controlState:UIControlStateNormal forSwitchIdentifier:switchIdentifier usingTemplate:self.templateBundle] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.iconColor = [panel primaryColorForSwitchIdentifier:switchIdentifier] ? [panel primaryColorForSwitchIdentifier:switchIdentifier] : [UIColor grayColor];
    return cell;
}

%new
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 28;
}

%new
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CCXPunchOutView *view = [[NSClassFromString(@"CCXPunchOutView") alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 28)];
    /* Create custom view to display section header... */
    view.cornerRadius = 13;
    view.roundCorners = 0;
    view.style = 0;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setFont:[[self class] sectionHeaderFont]];
    NSString *text;
     if (section == 0)
    	text = self.enabledSectionName;
    else if (section == 1)
    	text = self.disabledSectionName;

    [label setText:text];
    [view addSubview:label];

    // [self.primaryEffectConfig configureLayerView:label];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
   // [[NSClassFromString(@"CUIControlCenterVisualEffect")  effectWithControlState:0 inContext:6].effectConfig.contentConfig configureLayerView:label.layer];
    // CUIControlCenterVisualEffect

    label.translatesAutoresizingMaskIntoConstraints = NO;
	[view addConstraint:[NSLayoutConstraint constraintWithItem:label
		                                             attribute:NSLayoutAttributeCenterY
		                                             relatedBy:NSLayoutRelationEqual
		                                                toItem:view
		                                             attribute:NSLayoutAttributeCenterY
		                                             multiplier:1
		                                               constant:0]];
	[view addConstraint:[NSLayoutConstraint constraintWithItem:label
		                                             attribute:NSLayoutAttributeLeft
		                                             relatedBy:NSLayoutRelationEqual
		                                                toItem:view
		                                             attribute:NSLayoutAttributeLeft
		                                             multiplier:1
		                                               constant:15]];
	[view addConstraint:[NSLayoutConstraint constraintWithItem:label
		                                             attribute:NSLayoutAttributeRight
		                                             relatedBy:NSLayoutRelationEqual
		                                                toItem:view
		                                             attribute:NSLayoutAttributeRight
		                                             multiplier:1
		                                               constant:0]];
	[view addConstraint:[NSLayoutConstraint constraintWithItem:label
		                                             attribute:NSLayoutAttributeHeight
		                                             relatedBy:NSLayoutRelationEqual
		                                                toItem:view
		                                             attribute:NSLayoutAttributeHeight
		                                             multiplier:1
		                                               constant:0]];
		
    [view setBackgroundColor:nil];
    return view;
}
#pragma mark - Table view delegate
%new
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Navigation logic may go here. Create and push another view controller.
    // if (_detailViewController == nil) {
    //     _detailViewController = [[DetailViewController alloc] initWithNibName:nil bundle:nil];
    // }
        
    // // データを受け渡す
    // UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // _detailViewController.navigationItem.title = [[NSString alloc] initWithFormat:@"%@", cell.textLabel.text];
    // _detailViewController.textLabel.text = [[NSString alloc] initWithFormat:@"%@", cell.textLabel.text];
    
    // // Pass the selected object to the new view controller.
    // [self.navigationController pushViewController:_detailViewController animated:YES];
}

%new
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.01f;
}

%new
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	return [[UIView alloc] initWithFrame:CGRectZero];
}

%new
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

%new
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

%new
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 	return NO;
 }

 %new
 - (BOOL) tableView: (UITableView *) tableView canMoveRowAtIndexPath: (NSIndexPath *) indexPath {
 	return YES;
 }

 %new
 - (void)tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) fromIndexPath toIndexPath: (NSIndexPath *) toIndexPath {
	
	//[(UIPanGestureRecognizer *)[[[NSClassFromString(@"SBControlCenterController") sharedInstance] _controlCenterViewController] valueForKey:@"_panGesture"] setEnabled:NO];
	
	NSMutableArray *fromArray = fromIndexPath.section ? self.disabledIdentifiers : self.enabledIdentifiers;
	NSMutableArray *toArray = toIndexPath.section ? self.disabledIdentifiers : self.enabledIdentifiers;
	NSString *identifier = [fromArray objectAtIndex:fromIndexPath.row];
	[fromArray removeObjectAtIndex:fromIndexPath.row];
	[toArray insertObject:identifier atIndex:toIndexPath.row];
	[self _flushSettings];
	//[(UIPanGestureRecognizer *)[[[NSClassFromString(@"SBControlCenterController") sharedInstance] _controlCenterViewController] valueForKey:@"_panGesture"] setEnabled:YES];
	//[(UIPanGestureRecognizer *)[[[[NSClassFromString(@"SBControlCenterController") sharedInstance] _controlCenterViewController] valueForKey:@"_panGesture"] setEnabled:YES];
 	return;
}

%new
- (void)tableView:(UITableView *)tableView willBeginReorderingRowAtIndexPath:(NSIndexPath *)indexPath {
	[(UIPanGestureRecognizer *)[[[NSClassFromString(@"SBControlCenterController") sharedInstance] _controlCenterViewController] valueForKey:@"_panGesture"] setEnabled:NO];
}

%new
- (void)tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath {
	[(UIPanGestureRecognizer *)[[[NSClassFromString(@"SBControlCenterController") sharedInstance] _controlCenterViewController] valueForKey:@"_panGesture"] setEnabled:YES];
	// tableView.editing = NO;
	// tableView.editing = YES;
}

%new
- (void)tableView:(UITableView *)tableView didCancelReorderingRowAtIndexPath:(NSIndexPath *)indexPath {
	[(UIPanGestureRecognizer *)[[[NSClassFromString(@"SBControlCenterController") sharedInstance] _controlCenterViewController] valueForKey:@"_panGesture"] setEnabled:YES];
}

%new
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
    }    
}

%new
- (NSArray *)arrayForSection:(NSInteger)section
{
	return section ? self.disabledIdentifiers : self.enabledIdentifiers;
}

%new
- (void)_flushSettings
{
	if (self.preferencesApplicationID && (self.enabledKey || self.disabledKey)) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		if (self.enabledKey) {
			[dict setObject:self.enabledIdentifiers forKey:self.enabledKey];
		}
		if (self.disabledKey) {
			[dict setObject:self.disabledIdentifiers forKey:self.disabledKey];
		}
		CFPreferencesSetMultiple((CFDictionaryRef)dict, NULL, (__bridge CFStringRef)self.preferencesApplicationID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		CFPreferencesAppSynchronize((__bridge CFStringRef)self.preferencesApplicationID);
	}
	if (self.settingsFile) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.settingsFile] ?: [NSMutableDictionary dictionary];
		if (self.enabledKey) {
			[dict setObject:self.enabledIdentifiers forKey:self.enabledKey];
		}
		if (self.disabledKey) {
			[dict setObject:self.disabledIdentifiers forKey:self.disabledKey];
		}
		NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
		[data writeToFile:self.settingsFile atomically:YES];
	}
	if (self.notificationName) {
		notify_post([self.notificationName UTF8String]);
	}
}

%new
+ (UIFont *)sectionHeaderFont {
	UIFontDescriptor *descriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote] fontDescriptorWithFamily:@".SFUIText"];
	descriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitCondensed];
	return [UIFont fontWithDescriptor:descriptor size:0];
// 	return [UIFont fontWithName:@".SFUIText" size:font.pointSize-1*[UIScreen mainScreen].scale) traits:[font traits]];
}
%end