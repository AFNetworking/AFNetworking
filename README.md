#AFNetworking-SeatMe

This is a maintained fork of the popular AFNetworking library. 

## Differences from AFNetworking

A few of the improvements and changes over upstream include:

  * **Ability to override the cache storage policy** (this improves support for NSURLCache and replacements like SDURLCache)
  * **iOS Multitasking support built in.**
  * **Allows configuration of the callback queue used to return asynchronous responses** instead of hard coding to `main_queue`. (The queue usedf by default is the queue used to create the operation). 
  * **Better adherhance to the DRY (don't repeat yourself) principle**. Operation classes inheirt background processing capabilty instead of having the same code across all the operations classes.
  * **No reasonably unexpected behaviors or magic**. Instead prefer explict configuration. 
    * ```AFImageRequestOperation``` does not automagically scale your images 2x if on retina devices on iOS by default. 
    * ~~The JSON library used to decode responses is configurable and doesn't fallback under different OS versions.~~ (Integrated with upstream's solution to this.)
  * **Typedef'd blocks** - Many block declarations that used more than once have a `typedef`
  * **UI/Networking seperation** - Clearer seperation of networking and UI related code to make reusing code between Mac and iOS easier.
  * **More uniform across platforms** - Less ifdefs to change behavior between Mac and iOS versions. 
    * AFXMLRequestOperation is spilt into two classes (one that returns NSXMLParser that is avalaible on both iOS and Mac OSX, and one that returns an NSXMLDocument for only Mac OSX).
    * AFImageRequestOperation doesn't #ifdef every function and instead typedefs UIImage and NSImage internally to use a common type to improve code readabitly and only breaks into #ifdefs where behavior is different between the two image classes.
  * **Subclassable operations** - All Operation classes are completely subclassable. All implementation details in set in the convience methods have been moved to the operation's initializers allowing you to subclass them without issue. (as of 11/22/2011, upstream has started moving in this direction)
  * **Doesn't override the behavior of the ```completionBlock``` property** or remove access to it as a user. The design in this fork makes successBlock and failureBlock properties and makes them completely exclusive to ```completionBlock```.


##Motiviation for forking
AFNetworking is a wonderful library and one we use at SeatMe. In v0.5.0, we required a few modifications to prevent the NSOperations from calling back on the main_queue. Over time as we attempted to maintain these changes through newer releases of AFNetworking. However our code had diveraged a bit. We are working to attempt to re-integrate our changes as best we can in a way that is acceptible to upstream, time permiting in our develop cycles. It's our hope to fully integrate upstream at some point. Until then, in the spirt of openness, we are making our changes avaliable. 