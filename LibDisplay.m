//
//  LibDisplay.m
//  
//
//  Created by Kyle Howells on 22/12/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard4.0/SBAppSwitcherController.h>
#import <SpringBoard4.0/SBUIController.h>
#import <SpringBoard4.0/SBDisplayStack.h>
#import <SpringBoard4.0/SBApplication.h>
#import <SpringBoard4.0/SBDisplay.h>
#import <QuartzCore/QuartzCore.h>
#import "LibDisplay.h"

#define SPRINGBOARD         UIApp
#define UIApp               ((SpringBoard*)[UIApplication sharedApplication])
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface SpringBoard : UIApplication {}
- (void)setBackgroundingEnabled:(BOOL)backgroundingEnabled forDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBAppSwitcherController ()
-(id)sharedInstance;
//-(void)_removeApplicationFromRecents:(SBApplication*)app;
@end

@interface SBApplication ()
-(int)suspensionType;
@end

@interface SBProccess : NSObject {}
-(void)resume;
@end

@interface LibDisplay()
-(id)_init;
@property (nonatomic, readonly) NSMutableArray *delegates;
-(SBDisplayStack*)stackAtIndex:(int)index;

-(void)appLaunched:(SBApplication*)app;
-(void)appQuit:(SBApplication*)app;
@end


static LibDisplay *_instance;

@implementation LibDisplay
@synthesize displayStacks = _displayStacks;
@synthesize runningApplications = _runningApplications;
@synthesize delegates = _delegates;

#pragma mark - Singleton Methods

+(LibDisplay*)sharedInstance{
	@synchronized(self) {
        if (_instance == nil) {
            _instance = [[self alloc] _init];
        }
    }

    return _instance;
}

-(id)_init{
    if ((self = [super init])) {
        _displayStacks = [[NSMutableArray alloc] init];
        _runningApplications = [[NSMutableArray alloc] init];
        _delegates = [[NSMutableArray alloc] init];
    }

    return self;
}

// If I'm opensourcing it I don't want it to be crashed be something not realising it's a sharedInstance.
-(id)init{
    return [LibDisplay sharedInstance];
}


#pragma mark - Display stacks
-(SBDisplayStack*)SBWPreActivateDisplayStack{
    return [self stackAtIndex:0];
}
-(SBDisplayStack*)SBWActiveDisplayStack{
    return [self stackAtIndex:1];
}
-(SBDisplayStack*)SBWSuspendingDisplayStack{
    return [self stackAtIndex:2];
}
-(SBDisplayStack*)SBWSuspendedEventOnlyDisplayStack{
    return [self stackAtIndex:3];
}
-(SBDisplayStack*)stackAtIndex:(int)index{
    if (index < [self.displayStacks count]) {
        return [self.displayStacks objectAtIndex:index];
    }

    return nil;
}


#pragma mark - Application stuff
-(SBApplication*)topApplication{
    return [[self SBWActiveDisplayStack] topApplication];
}

#pragma mark Application Lifetime
-(void)appLaunched:(SBApplication*)app{
    if (![self.runningApplications containsObject:app]) {
        [self.runningApplications addObject:app];

        for (NSObject <LibDisplayDelegate> *delegate in self.delegates) {
            [delegate performSelector:@selector(applicationDidLaunch:) withObject:app];
        }
    }
}
-(void)appQuit:(SBApplication*)app{
    if ([self.runningApplications containsObject:app]) {
        [self.runningApplications removeObject:app];

        for (NSObject <LibDisplayDelegate> *delegate in self.delegates) {
            if (delegate && [delegate respondsToSelector:@selector(applicationDidQuit:)]) {
                [delegate performSelector:@selector(applicationDidQuit:) withObject:app];
            }
        }
    }
}

-(void)notifyOfAppLaunches:(id <LibDisplayDelegate>)new_delegate{
    if (![self.delegates containsObject:new_delegate]) {
        [self.delegates addObject:new_delegate];
    }
}
-(void)removeNotifier:(id <LibDisplayDelegate>)existing_delegate{
    if ([self.delegates containsObject:existing_delegate]) {
        [self.delegates removeObject:existing_delegate];
    }
}


#pragma mark - Active and deactivate applications
-(void)activateApplication:(SBApplication *)toApp animated:(BOOL)animated{
    // Get the currently open application.
    SBApplication *fromApp = [self topApplication];

    // Check if it's the same as the currently open application, if it is there's nothing todo.
	if ([[toApp displayIdentifier] isEqualToString:[fromApp displayIdentifier]])
        return;

    // If animated they want the system default (app to app transition, or zoom on homescreen).
    if (animated && toApp) {
        [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:toApp];
        return; // Done, wasn't that easy.
    }

    // Now, if we were asked to, open the other app.
    if (toApp) {
        [toApp clearDisplaySettings];
        [toApp clearActivationSettings];
        [toApp clearDeactivationSettings];

        // 20 = appToApp
        [toApp setActivationSetting:20 flag:YES];

        // Note if it's a large application the user might see a brief flash of the homescreen.
        [[self SBWPreActivateDisplayStack] pushDisplay:toApp];
    }
    

    // If another app is open then close it
    if (fromApp) {
        // Clear any animation settings the app may have
        [fromApp clearDisplaySettings];
        [fromApp clearActivationSettings];
        [fromApp clearDeactivationSettings];

        // Now pop is from the Active displayStack
        [[self SBWActiveDisplayStack] popDisplay:fromApp];
        // And push it onto the Suspending displayStack
        [[self SBWSuspendingDisplayStack] pushDisplay:fromApp];
    }

    if (!toApp) {
        // The user should now be on the homescreen.
        // There's a bug above 4.? (4.1 or 4.2 I think) where the status bar won't be there.

        SBUIController *uiController = (SBUIController*)[objc_getClass("SBUIController") sharedInstance];
        if ([uiController respondsToSelector:@selector(createFakeSpringBoardStatusBar)]) {
            [uiController createFakeSpringBoardStatusBar];
        }
    }
}

-(void)quitApplication:(SBApplication*)application{
    [self quitApplication:application removeFromSwitcher:NO];
}
-(void)quitApplication:(SBApplication*)application removeFromSwitcher:(BOOL)removeFromSwitcher{
    if ([SPRINGBOARD respondsToSelector:@selector(setBackgroundingEnabled:forDisplayIdentifier:)]) {
        [SPRINGBOARD setBackgroundingEnabled:NO forDisplayIdentifier:[application displayIdentifier]];
    }

    // On iOS 4.0 it crashes springboard, but after a delay so I don't know why.
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"4.1")) {
        //******************* Proper app quiting code thanks to 'jmeosbn' - start **************//

        int suspendType = [application respondsToSelector:@selector(_suspensionType)] ? [application _suspensionType] : [application suspensionType];
        
        // Set app to terminate on suspend then call deactivate
        // Allows exiting root apps, even if already backgrounded,
        // but does not exit an app with active background tasks
        [application setSuspendType:0];
        [application deactivate];
        [[application process] resume];
        
        // Restore previous suspend type
        [application setSuspendType:suspendType];

        //******************* Proper app quiting code thanks to 'jmeosbn' - end **************//
    }

    // Now if it hasn't closed after 1/2 second kill it (doesn't work on root apps like iFile)
    [application performSelector:@selector(kill) withObject:nil afterDelay:0.4];    // Probably un-needed
    //[[objc_getClass("SBAppSwitcherController") sharedInstance] _quitButtonHit:APP];

    if (removeFromSwitcher) {
        SBAppSwitcherController *appSwitcherController = (SBAppSwitcherController*)[objc_getClass("SBAppSwitcherController") sharedInstance];
        if ([appSwitcherController respondsToSelector:@selector(_removeApplicationFromRecents:)]) {
            [appSwitcherController _removeApplicationFromRecents:application];
        }
    }
}

#pragma mark - Init Methods
-(id)retain{
    return self;
}

-(unsigned)retainCount{
    return UINT_MAX;
}

-(void)release{}

-(id)autorelease{
    return self;
}

@end
