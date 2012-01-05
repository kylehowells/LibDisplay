# LibDisplay #
----------------------------
##Overview##

Lots of tweaks need to find out if an app is currently open, or even to open them itself. The way it does this is to use the SBDisplayStacks, however as there isn't an iVar in any classes that give them to you each tweak hooks the init & dealloc methods of that class. Then each tweak tracks them itself.
Another thing it does is track which applications are actually running at any one time by maintaining an array of running applications.
This also manages launching applications for you. If you want to launch an application animated it'll let iOS perform the standard app switch animation (which is about 0.5-0.6 seconds). However if you don't what an animation but instead to switch instantly from one app to another it'll push and pop the applications itself to the various displayStacks.
Even if no one else finds this useful I'll be able to minimise code in my own tweaks.


---------------------------

## Usage ##

#### Get currently running applications ####

Returns an NSArray ordered oldest to newest.

    [LibDisplay sharedInstance].runningApplications


#### Set your own object to be notified of apps launching and exiting (like a delegate) ####

To allow multiple tweaks to use this I decided against a standard delegate and went for this instead.
Each object sent most conform to the 'LibDisplayDelegate' protocol.

    // Add delegate
    [[LibDisplay sharedInstance] notifyOfAppLaunches:self];
    // Remove delegate
    [[LibDisplay sharedInstance] removeNotifier:self];


#### Switch applications ####

LibDisplay can also switch applications for you. Most of the time you'll want to animate between apps as that is what iOS does and so is what the user expects. In this case LibDisplay will tell iOS's built in method (SBUIController activate...) to switch applications.
However if you do your own animation such as CardSwitcher does then behind this clever little animation you just what the apps to switch instantly, that way you can control exactly how long or short the animation the user sees should be.

    // Activate an app with the default switcher animation.
    [[LibDisplay sharedInstance] activateApplication:toApp animated:YES];

    // Deactivate the currently open application (the animated flag is pointless here)
    [[LibDisplay sharedInstance] activateApplication:nil animated:YES];

    // Activate an application instantly.
    // If it is already backgrounded it'll appear instantly, else it'll appear as soon as it has loaded into memory.
    [[LibDisplay sharedInstance] activateApplication:toApp animated:NO];


### Possible Future Features ###

*  Get a UIImage of a currently running application.
*  Get a live view of an open app? (would be pointless mostly, just use the SBApplication methods).
* ? (I can't think of anything else really)
