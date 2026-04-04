# FLEXD

<img alt="Screenshot" src="https://raw.githubusercontent.com/TimOliver/FLEXD/refs/heads/main/screenshot.webp">

[FLEX (Flipboard Explorer)](https://github.com/FLEXTool/FLEX) is a set of in-app debugging and exploration tools for iOS development. When presented, FLEX shows a toolbar that lives in a window above your application. From this toolbar, you can view and modify nearly every piece of state in your running application.

FLEXD is my own personal fork of the original FLEX framework. I'd been using FLEX heavily during my time at Instagram, and it was absolutely indispensible when working on the [Instagram for iPad](https://about.instagram.com/blog/announcements/instagram-for-ipad) project. That being said, the toolbar's edge-to-edge design felt quite strange on large iPad screens, and in general, the look of the framework has slowly started to show its age, especially now that iOS 26 has arrived.

Since I had a very different vision of how I think FLEX should look and feel in 2026, instead of barging in and submitting an absolute mountain of PRs to the original repo that might blindside *many* users, I thought I'd keep things separate for now so I can experiment at my own leisure. But I'm certainly open to submitting these changes back upstream if there's demand!

In any case, feel free to play with this version and let me know what you think!

## Features of FLEX
- Inspect and modify views in the hierarchy.
- See the properties and ivars on any object.
- Dynamically modify many properties and ivars.
- Dynamically call instance and class methods.
- Observe detailed network request history with timing, headers, and full responses.
- Add your own simulator keyboard shortcuts.
- View system log messages (e.g. from `NSLog`).
- Access any live object via a scan of the heap.
- View the file system within your app's sandbox.
- Browse SQLite/Realm databases in the file system.
- Trigger 3D touch in the simulator using the control, shift, and command keys.
- Explore all classes in your app and linked systems frameworks (public and private).
- Quickly access useful objects such as `[UIApplication sharedApplication]`, the app delegate, the root view controller on the key window, and more.
- Dynamically view and modify `NSUserDefaults` values.

Unlike many other debugging tools, FLEX runs entirely inside your app, so you don't need to be connected to LLDB/Xcode or a different remote debugging server. It works well in the simulator and on physical devices.


## Usage

In the iOS simulator, you can use keyboard shortcuts to activate FLEX. `f` will toggle the FLEX toolbar. Hit the `?` key for a full list of shortcuts. You can also show FLEX programmatically:

Short version:

```objc
// Objective-C
[[FLEXManager sharedManager] showExplorer];
```

```swift
// Swift
FLEXManager.shared.showExplorer()
```

More complete version:

```objc
#if DEBUG
#import "FLEXManager.h"
#endif

...

- (void)handleSixFingerQuadrupleTap:(UITapGestureRecognizer *)tapRecognizer
{
#if DEBUG
    if (tapRecognizer.state == UIGestureRecognizerStateRecognized) {
        // This could also live in a handler for a keyboard shortcut, debug menu item, etc.
        [[FLEXManager sharedManager] showExplorer];
    }
#endif
}
```


## Feature Examples
### Modify Views
Once a view is selected, you can tap on the info bar below the toolbar to present more details about the view. From there, you can modify properties and call methods.

<img alt="Modify Views" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271816-c5c2b480-176c-11ea-8bf4-2c5a755bc392.gif>

### Network History
When enabled, network debugging allows you to view all requests made using NSURLConnection or NSURLSession. Settings allow you to adjust what kind of response bodies get cached and the maximum size limit of the response cache. You can choose to have network debugging enabled automatically on app launch. This setting is persisted across launches.

<img alt="Network History" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271876-e5f27380-176c-11ea-98ef-24170205b706.gif>

### All Objects on the Heap
FLEX queries malloc for all the live allocated memory blocks and searches for ones that look like objects. You can see everything from here.

<img alt="Heap/Live Objects Explorer" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271850-d83cee00-176c-11ea-9750-ee3a479c6769.gif>

### Explore-at-address

If you get your hands on an arbitrary address, you can try explore the object at that address, and FLEX will open it if it can verify the address points to a valid object. If FLEX isn't sure, it'll warn you and refuse to dereference the pointer. If you know better, however, you can choose to explore it anyway by choosing "Unsafe Explore"

<img alt="Address Explorer" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271798-bb081f80-176c-11ea-806d-9d74ac293641.gif>

### Simulator Keyboard Shortcuts
Default keyboard shortcuts allow you to activate the FLEX tools, scroll with the arrow keys, and close modals using the escape key. You can also add custom keyboard shortcuts via `-[FLEXManager registerSimulatorShortcutWithKey:modifiers:action:description]`

<img alt="Simulator Keyboard Shortcuts" width=40% height=40% src="https://user-images.githubusercontent.com/8371943/70272984-d3793980-176e-11ea-89a2-66d187d71b4c.png">

### File Browser
View the file system within your app's bundle or sandbox container. FLEX shows file sizes, image previews, and pretty prints `.json` and `.plist` files. You can rename and delete files and folders. You can "share" any file if you want to inspect them outside of your app.

<img alt="File Browser" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271831-d115e000-176c-11ea-8078-ada291f980f3.gif>

### SQLite Browser
SQLite database files (with either `.db` or `.sqlite` extensions), or [Realm](https://realm.io) database files can be explored using FLEX. The database browser lets you view all tables, and individual tables can be sorted by tapping column headers.

<img alt="SQLite Browser" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271881-ea1e9100-176c-11ea-9a42-01618311c869.gif>

### 3D Touch in the Simulator
Using a combination of the command, control, and shift keys, you can simulate different levels of 3D touch pressure in the simulator. Each key contributes 1/3 of maximum possible force. Note that you need to move the touch slightly to get pressure updates.

<img alt="Simulator 3D Touch" width=36% height=36% src=https://cloud.githubusercontent.com/assets/1422245/11786615/5d4ef96c-a23c-11e5-975e-67275341e439.gif>

### Explore Loaded Libraries
Go digging for all things public and private. To learn more about a class, you can create an instance of it and explore its default state. You can also type in a class name to jump to that class directly if you know which class you're looking for.

<img alt="Loaded Libraries Exploration" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271868-dffc9280-176c-11ea-8704-a0c05b75cc5f.gif>

### NSUserDefaults Editing
FLEX allows you to edit defaults that are any combination of strings, numbers, arrays, and dictionaries. The input is parsed as `JSON`. If other kinds of objects are set for a defaults key (i.e. `NSDate`), you can view them but not edit them.

<img alt="NSUserDefaults Editing" width=36% height=36% src=https://user-images.githubusercontent.com/8371943/70271889-edb21800-176c-11ea-92b4-71e07d2b6ce7.gif>

### Learning from Other Apps
The code injection is left as an exercise for the reader. :innocent:

<p float="left">
    <img alt="Springboard Lock Screen" width=25% height=25% src= https://engineering.flipboard.com/assets/flex/flex-readme-reverse-1.png>
    <img alt="Springboard Home Screen" width=25% height=25% src= https://engineering.flipboard.com/assets/flex/flex-readme-reverse-2.png>
</p>


## Installation

FLEXD requires an app that targets iOS 15 or higher. To run the Example project, simply open the Xcode project in the Example folder. The project will import the local copy of FLEX automatically via Swift Pacakage Manager.

### Manual

Manually add the files in `Classes/` to your Xcode project, or just drag in the entire `FLEX/` folder. Be sure to exclude FLEX from `Release` builds or your app will be rejected.

##### Silencing warnings

Add the following flags to  to **Other Warnings Flags** in **Build Settings:** 

- `-Wno-deprecated-declarations`
- `-Wno-strict-prototypes`
- `-Wno-unsupported-availability-guard`


## Excluding FLEX from Release (App Store) Builds

FLEX makes it easy to explore the internals of your app, so it is not something you should expose to your users. Fortunately, it is easy to exclude FLEX files from Release builds. The strategies differ depending on how you integrated FLEX in your project, and are described below.

Wrap the places in your code where you integrate FLEX with an `#if DEBUG` statement to ensure the tool is only accessible in your `Debug` builds and to avoid errors in your `Release` builds. For more help with integrating FLEX, see the example project.

### Swift Package Manager

In Xcode, navigate to `Build Settings > Build Options > Excluded Source File Names`. For your `Release` configuration, set it to `FLEX*` like this to exclude all files with the `FLEX` prefix:

<img width=75% height=75% src=https://user-images.githubusercontent.com/1234765/98673373-8545c080-2357-11eb-9587-0743998e23ba.png>


### FLEX files added manually to a project

In Xcode, navigate to `Build Settings > Build Options > Excluded Source File Names`. For your `Release` configuration, set it to `FLEX*` like this to exclude all files with the `FLEX` prefix:

<img width=75% height=75% src=https://user-images.githubusercontent.com/8371943/70281926-e21d1c00-1781-11ea-92eb-aee340791da8.png>

## Additional Notes

- When setting fields of type `id` or values in `NSUserDefaults`, FLEX attempts to parse the input string as `JSON`. This allows you to use a combination of strings, numbers, arrays, and dictionaries. If you want to set a string value, it must be wrapped in quotes. For ivars or properties that are explicitly typed as `NSStrings`, quotes are not required.
- You may want to disable the exception breakpoint while using FLEX. Certain functions that FLEX uses throw exceptions when they get input they can't handle (i.e. `NSGetSizeAndAlignment()`). FLEX catches these to avoid crashing, but your breakpoint will get hit if it is active.

## Thanks & Credits
A an absolutely massive thanks to [Ryan Olsen](https://github.com/ryanolsonk), [Tanner Bennett](https://github.com/NSExceptional) and everyone else who has been building and supporting FLEX all these years. 

In addition, FLEX builds on ideas and inspiration from open source tools that came before it. The following resources have been particularly helpful:
- [MirrorKit](https://github.com/NSExceptional/MirrorKit): an Objective-C wrapper around the Objective-C runtime.
- [DCIntrospect](https://github.com/domesticcatsoftware/DCIntrospect): view hierarchy debugging for the iOS simulator.
- [PonyDebugger](https://github.com/square/PonyDebugger): network, core data, and view hierarchy debugging using the Chrome Developer Tools interface.
- [Mike Ash](https://www.mikeash.com/pyblog/): well written, informative blog posts on all things obj-c and more. The links below were very useful for this project:
 - [MAObjCRuntime](https://github.com/mikeash/MAObjCRuntime)
 - [Let's Build Key Value Coding](https://www.mikeash.com/pyblog/friday-qa-2013-02-08-lets-build-key-value-coding.html)
 - [ARM64 and You](https://www.mikeash.com/pyblog/friday-qa-2013-09-27-arm64-and-you.html)
- [RHObjectiveBeagle](https://github.com/heardrwt/RHObjectiveBeagle): a tool for scanning the heap for live objects. It should be noted that the source code of RHObjectiveBeagle was not consulted due to licensing concerns.
- [heap_find.cpp](https://www.opensource.apple.com/source/lldb/lldb-179.1/examples/darwin/heap_find/heap/heap_find.cpp): an example of enumerating malloc blocks for finding objects on the heap.
- [Gist](https://gist.github.com/samdmarshall/17f4e66b5e2e579fd396) from [@samdmarshall](https://github.com/samdmarshall): another example of enumerating malloc blocks.
- [Non-pointer isa](http://www.sealiesoftware.com/blog/archive/2013/09/24/objc_explain_Non-pointer_isa.html): an explanation of changes to the isa field on iOS for ARM64 and mention of the useful `objc_debug_isa_class_mask` variable.
- [GZIP](https://github.com/nicklockwood/GZIP): A library for compressing/decompressing data on iOS using libz.
- [FMDB](https://github.com/ccgus/fmdb): This is an Objective-C wrapper around SQLite.
- [InAppViewDebugger](https://github.com/indragiek/InAppViewDebugger): The inspiration and reference implementation for FLEX 4's 3D view explorer, by @indragiek.

