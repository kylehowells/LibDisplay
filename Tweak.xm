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

//    NSLog(@"SBAppSwitcherController: -applicationLaunched: %@", app);
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

//    NSLog(@"SBAppSwitcherModel: -addToFront: %@", app);
    [[LibDisplay sharedInstance] addToFront:app];
}
-(void)remove:(id)app{
    %orig;
    
//    NSLog(@"SBAppSwitcherModel: -remove: %@", app);
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




// iOS 6
-(void)didLaunch:(id)arg1{
	%log;
	[[LibDisplay sharedInstance] appFinishedLaunching:self];
	
    %orig;
}
-(void)didExitWithInfo:(id)arg1 type:(int)arg2{
	[[LibDisplay sharedInstance] appQuit:self];
    
    %orig;
}
%end

/**** iOS 6 ****/
/*%hook BKSWorkspace
-(void)activate:(id)arg1 withActivation:(id)arg2{ %log; NSLog(@"%@", [arg1 class]); return %orig; }
-(void)_acquireApplicationActivationAssertion:(id)arg1 uniqueID:(id)arg2 name:(id)arg3{ %log; return %orig; }
-(void)_releaseApplicationActivationAssertion:(id)arg1{ %log; return %orig; }
%end*/

%ctor{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;
    [pool release];
}
