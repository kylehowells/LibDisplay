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


#pragma mark - Headers
@interface SpringBoard : UIApplication {}
-(void)setBackgroundingEnabled:(BOOL)backgroundingEnabled forDisplayIdentifier:(NSString *)displayIdentifier;
-(void)showSpringBoardStatusBar;
@end

@interface SBAppSwitcherModel : NSObject {}
+(SBAppSwitcherModel*)sharedInstance;
-(void)addToFront:(id)front;
-(void)remove:(id)remove;
@end

@interface SBApplicationController : NSObject {}
+(SBApplicationController*)sharedInstance;
-(SBApplication*)applicationWithDisplayIdentifier:(NSString*)displayIdentifier;
@end

@interface SBUIController ()
-(void)dismissSwitcherAnimated:(BOOL)animated;
@end

@interface SBApplication ()
-(int)suspensionType;
@end

@interface SBProccess : NSObject {}
-(void)resume;
@end


#pragma mark - Private methods
@interface LibDisplay()
-(id)_init;
@property (nonatomic, readonly) NSMutableArray *launchedApps;
@property (nonatomic, readonly) NSMutableArray *delegates;
-(SBDisplayStack*)stackAtIndex:(int)index;

-(void)appLaunched:(SBApplication*)app;
-(void)appFinishedLaunching:(SBApplication*)app;
-(void)appQuit:(SBApplication*)app;

-(void)addToFront:(SBApplication*)app;
-(void)closeSwitcher;
@end


static BOOL sbAppNotNSString = NO;
static LibDisplay *_instance;

@implementation LibDisplay
@synthesize displayStacks = _displayStacks;
@synthesize runningApplications = _runningApplications;
@synthesize launchedApps = _launchedApps;
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
        _launchedApps = [[NSMutableArray alloc] init];
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

-(BOOL)applicationIsLaunching:(SBApplication*)application{
    return (![self.launchedApps containsObject:application] && [self.runningApplications containsObject:application]);
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
-(void)appFinishedLaunching:(SBApplication*)app{
    if (![self.launchedApps containsObject:app] && [self.runningApplications containsObject:app]) {
        [self.launchedApps addObject:app];
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

    if ([self.launchedApps containsObject:app]) {
        [self.launchedApps removeObject:app];
    }
}
// Hacky stuff here :( it changed from SBApplication to NSString but without
// changing the method names at all so you can't work out what it wants. + it
// has always just stored the displayID so looking at the array iVar won't help either.
-(void)addToFront:(id)app{
    //NSLog(@"what is -addToFront: %@", app);
    NSMutableArray *array = self.runningApplications;

    if ([app isKindOfClass:[NSString class]]) {
        app = [(SBApplicationController*)[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:app];
    }

    if (app) {
        sbAppNotNSString = YES
        if ([array containsObject:app]) {
            [array removeObject:app];
            [array addObject:app];
        }
        else {
            [self appLaunched:app];
        }
    }
}

#pragma mark - Send delegates info.
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
        // Prevent seeing and interacting with the homescreen
        SBUIController *uiController = (SBUIController*)[objc_getClass("SBUIController") sharedInstance];
        if ([uiController respondsToSelector:@selector(fadeIconsForScatter:duration:startTime:)]) {
            [uiController fadeIconsForScatter:YES duration:0 startTime:CACurrentMediaTime()];
        }

        [toApp clearDisplaySettings];
        [toApp clearActivationSettings];
        [toApp clearDeactivationSettings];

        if (fromApp) {
            // 20 = appToApp
            [toApp setActivationSetting:20 flag:YES];
        }

        // Note if it's a large application the user might see a brief flash of the homescreen.
        [[self SBWPreActivateDisplayStack] pushDisplay:toApp];
    }
    

    // If another app is open then close it
    if (fromApp) {
        // Clear any animation settings the app may have
        [fromApp clearDisplaySettings];
        [fromApp clearActivationSettings];
        [fromApp clearDeactivationSettings];

        if (!toApp) {
            SpringBoard *springBoard = UIApp;
            if ([springBoard respondsToSelector:@selector(showSpringBoardStatusBar)]) {
                [springBoard showSpringBoardStatusBar];
            }

//            if ([SPRINGBOARD respondsToSelector:@selector(setBackgroundingEnabled:forDisplayIdentifier:)]) {
//                // Animate (to fix a backgrounder related bug)
//                [fromApp setDeactivationSetting:2 flag:YES];
//            }
        }

        // Now pop is from the Active displayStack
        [[self SBWActiveDisplayStack] popDisplay:fromApp];
        // And push it onto the Suspending displayStack
        [[self SBWSuspendingDisplayStack] pushDisplay:fromApp];
    }

    [self closeSwitcher];
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
        [self removeApplicationFromSwitcher:application];
    }
}

-(void)removeApplicationFromSwitcher:(SBApplication*)app{
//    SBAppSwitcherController *appSwitcherController = (SBAppSwitcherController*)[objc_getClass("SBAppSwitcherController") sharedInstance];
//    if ([appSwitcherController respondsToSelector:@selector(_removeApplicationFromRecents:)]) {
//        // The app isn't in the recents list if it's currently open.
//        [appSwitcherController _removeApplicationFromRecents:application];
//    }

    SBAppSwitcherModel *switcherModel = (SBAppSwitcherModel*)[objc_getClass("SBAppSwitcherModel") sharedInstance];
    if ([switcherModel respondsToSelector:@selector(remove:)]) {
        // remove: takes an SBApplication on iOS 4 but an NSString on iOS 5 :(
        if (SYSTEM_VERSION_LESS_THAN(@"5.0") || sbAppNotNSString) {
            [switcherModel remove:app];
        }
        else {
            [switcherModel remove:app.displayIdentifier];
        }
    }
}

-(void)closeSwitcher{
    SBUIController *uiController = (SBUIController*)[objc_getClass("SBUIController") sharedInstance];

    if ([uiController isSwitcherShowing]) {
        if ([uiController respondsToSelector:@selector(_dismissSwitcher:)]) {
            [uiController _dismissSwitcher:0.0];
        }
        else if ([uiController respondsToSelector:@selector(dismissSwitcherAnimated:)]) {
            [uiController dismissSwitcherAnimated:NO];
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
