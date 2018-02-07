#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "NativeViewController.h"

@interface AppDelegate()
    @property (nonatomic, strong) NativeViewController *nativeViewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
    NSLog(@"her 1");
    
    UIViewController *flutterViewController = [[FlutterViewController alloc] init];
    self.nativeViewController = [[NativeViewController alloc] init]; //initWithRootViewController:flutterViewController];
    //[self.nativeViewController setNavigationBarHidden:YES];
    
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = flutterViewController;//self.nativeViewController;
    //[self.window makeKeyAndVisible];
    
  // Override point for customization after application launch.
    [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}



@end
