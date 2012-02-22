//
//  LibDisplay.h
//  
//
//  Created by Kyle Howells on 22/12/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//
//
//  This was developed for iOS 5.0 specifically, although has been tested successfully down to iOS 4.0
//  It uses the operating systems built in multitasking to track applications launching and closing.
//  The information this is based on can be found here:
//  - http://iky1e.tumblr.com/post/13985531616/raw-log-sbdisplay-settings
//  - http://code.google.com/p/iphone-tweaks/wiki/DevelopmentNotes
//  - http://iphonedevwiki.net/index.php/Special:AllPages

#import <Foundation/Foundation.h>

@class SBDisplayStack;
@class SBApplication;

@protocol LibDisplayDelegate <NSObject>
-(void)applicationDidLaunch:(SBApplication*)app;
-(void)applicationDidQuit:(SBApplication*)app;
@end


@interface LibDisplay : NSObject {}
+(LibDisplay*)sharedInstance;

#pragma mark - Display stacks
@property (nonatomic, readonly) NSMutableArray *displayStacks;
-(SBDisplayStack*)SBWPreActivateDisplayStack;
-(SBDisplayStack*)SBWActiveDisplayStack;
-(SBDisplayStack*)SBWSuspendingDisplayStack;
-(SBDisplayStack*)SBWSuspendedEventOnlyDisplayStack;

#pragma mark - Application stuff
@property (nonatomic, readonly) NSMutableArray *runningApplications;    // The array's order is oldest to newest opened.
-(SBApplication*)topApplication;    // Currently open application.
-(BOOL)applicationIsLaunching:(SBApplication*)application; // Is it still opening?

-(void)activateApplication:(SBApplication *)toApp animated:(BOOL)animated;  // Done I think
// Quit applications - (can't close root apps (iFile) below iOS 4.1)
-(void)quitApplication:(SBApplication*)application; // Defaults to NO
-(void)quitApplication:(SBApplication*)application removeFromSwitcher:(BOOL)removeFromSwitcher;
-(void)removeApplicationFromSwitcher:(SBApplication*)app;

#pragma mark - Track apps opening and closing
// Rather then a single 'delegate' I thought this would let lots of tweaks track apps opening and closing.

// Ask to be notified of app launches
-(void)notifyOfAppLaunches:(id <LibDisplayDelegate>)new_delegate;
// Ask to be notified of app closes
-(void)removeNotifier:(id <LibDisplayDelegate>)existing_delegate;
// This is only really useful for something like CardSwitcher or Multifl0w that displays the currently running...
//... apps. So if while it's open an app closes that should be removed from their interfaces.

@end
