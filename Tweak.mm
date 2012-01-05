#import "LibDisplay.h"

@interface LibDisplay()
-(void)appLaunched:(SBApplication*)app;
-(void)appQuit:(SBApplication*)app;
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
    
    [[LibDisplay sharedInstance] appLaunched:app];
}

-(void)applicationDied:(SBApplication*)app{
    [[LibDisplay sharedInstance] appQuit:app];
    
    %orig;
}
%end


%hook SBApplication
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
