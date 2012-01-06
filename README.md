# LibDisplay #

##Overview##

Lots of tweaks need to find out if an app is currently open, or even to open them itself. The way it does this is to use the SBDisplayStacks, however as there isn't an iVar in any classes that give them to you each tweak hooks the init & dealloc methods of that class. Then each tweak tracks them itself.
Another thing it does is track which applications are actually running at any one time by maintaining an array of running applications.
This also manages launching applications for you. If you want to launch an application animated it'll let iOS perform the standard app switch animation (which is about 0.5-0.6 seconds). However if you don't what an animation but instead to switch instantly from one app to another it'll push and pop the applications itself to the various displayStacks.
Even if no one else finds this useful I'll be able to minimise code in my own tweaks.


## Usage ##

---------------------------

#### Get currently running applications ####

Returns an NSArray ordered oldest to newest.

    [LibDisplay sharedInstance].runningApplications


---------------------------

#### Get currently open application ####

Get an SBApplication object of the application currently in the foreground, will be nil if on homescreen.

    [LibDisplay sharedInstance].topApplication


---------------------------

#### Get the displayStacks ####

Although part of the point of LibDisplay is that you shouldn't need to you can, if you wish get the displayStacks themselves (or if you need even more control get the array of the displayStacks).

    // Array of the displayStacks
    [LibDisplay sharedInstance].displayStacks

    // The displayStack you push launching applications onto.
    [[LibDisplay sharedInstance] SBWPreActivateDisplayStack]

    // The displayStack of displays currently showing, how we get the currently open app.
    [[LibDisplay sharedInstance] SBWActiveDisplayStack]

    // The displayStack you push closing displays onto.
    [[LibDisplay sharedInstance] SBWSuspendingDisplayStack]

    // I guess the displayStack things like skype are backgrounded to???
    [[LibDisplay sharedInstance] SBWSuspendedEventOnlyDisplayStack;


---------------------------

#### Set your own object to be notified of apps launching and exiting (like a delegate) ####

To allow multiple tweaks to use this I decided against a standard delegate and went for this instead.
Each object sent most conform to the 'LibDisplayDelegate' protocol.

    // Add delegate
    [[LibDisplay sharedInstance] notifyOfAppLaunches:self];
    // Remove delegate
    [[LibDisplay sharedInstance] removeNotifier:self];


---------------------------

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


---------------------------

#### Close applications ####

LibDisplay can also quit applications as well as launch them.
This is the part that needs work [app kill] works on most apps but has 2 problems, it crashes them (kill = instant) so they don't do there close down methods like saving ect... & it doesn't work on root apps (namely iFile being the one people will notice). I was given some code to close apps properly by "@jmeosbn" on GitHub. However it causes a weird SpringBoard crash on iOS 4.0 and as it doesn't crash instantly but after a delay I haven't be able to/tried much to fix it. There's a hacky solution where it'll only run his code if on iOS 4.1+ as that's what I tested it as working on. It works quite well, however I would like to improve this method.

    // Quit an application (won't remove from the app switcher)
    [[LibDisplay sharedInstance] quitApplication:app];

    // Quit an application and specify if you want it removed the app switcher as well.
    [[LibDisplay sharedInstance] quitApplication:app removeFromSwitcher:YES];



---------------------------

### Possible Future Features ###

*  Get a UIImage of a currently running application.
*  Get a live view of an open app? (would be pointless mostly, just use the SBApplication methods).
* ? (I can't think of anything else really)
