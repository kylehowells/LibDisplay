#import "LibDisplay.h"

@interface LibDisplay()
@property (nonatomic, readonly) NSMutableArray *launchedApps;
-(void)appLaunched:(SBApplication*)app;
-(void)appFinishedLaunching:(SBApplication*)app;
-(void)appQuit:(SBApplication*)app;
-(void)addToFront:(SBApplication*)app;
@end

#pragma mark - Display stacks
%hook SBDisplayStack
-(id)init{
	if ((self = %orig)) {
        [[LibDisplay sharedInstance].displayStacks addObject:self];
	}

	return self;
}

-(void)dealloc{
	[[LibDisplay sharedInstance].displayStacks removeObject:self];

	%orig;
}
%end


#pragma mark - Application tracking
%hook SBAppSwitcherController
-(void)applicationLaunched:(SBApplication*)app{
    %orig;

    NSLog(@"SBAppSwitcherController: -applicationLaunched: %@", app);
    [[LibDisplay sharedInstance] appLaunched:app];
}

-(void)applicationDied:(SBApplication*)app{
    [[LibDisplay sharedInstance] appQuit:app];
    
    %orig;
}
%end


%hook SBAppSwitcherModel
// = SBApplication on 4.x, but an NSString on 5.0
-(void)addToFront:(id)app{
    %orig;

    NSLog(@"SBAppSwitcherModel: -addToFront: %@", app);
    [[LibDisplay sharedInstance] addToFront:app];
}
-(void)remove:(id)app{
    %orig;
    
    NSLog(@"SBAppSwitcherModel: -remove: %@", app);
}
%end


%hook SBApplication
- (void)launchSucceeded:(BOOL)arg1 {
    [[LibDisplay sharedInstance] appFinishedLaunching:self];

    %orig;
}

-(void)exitedCommon{
    [[LibDisplay sharedInstance] appQuit:self];
    
    %orig;
}
%end


%ctor{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;
    [pool release];
}
