#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <MapKit/MapKit.h>

@interface AppDelegate()
    @property (nonatomic, strong) CLLocationManager *locationManager;
    @property (nonatomic) FlutterBasicMessageChannel* messageChannel;
@end

static NSString* const emptyString = @"";
static NSString* const channel = @"increment";

@implementation AppDelegate

- (NSString*) messageName {
  return channel;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {


    self.messageChannel = [ FlutterBasicMessageChannel messageChannelWithName:channel
                            binaryMessenger:self.window.rootViewController
                            codec:[FlutterStringCodec sharedInstance]];
/*
MainViewController*  __weak weakSelf = self;
[self.messageChannel setMessageHandler:^(id message, FlutterReply reply) {
  [weakSelf.nativeViewController didReceiveIncrement];
  reply(emptyString);
}];
*/
    self.locationManager = [[CLLocationManager alloc] init];

    // Setup location tracker accuracy
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    // Distance filter
    self.locationManager.distanceFilter = 5.0f;

    // Assign location tracker delegate
    self.locationManager.delegate = self;


    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    // For iOS9 we have to call this method if we want to receive location updates in background mode
    if([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }

    [self.locationManager startMonitoringSignificantLocationChanges];

    [GeneratedPluginRegistrant registerWithRegistry:self];

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"Go to terminate");
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Did update location!");

    // For real cases we should filter location array by accuracy
    // And check timestamp if you need real time tracking
    // By we don't do it here
    CLLocation *location = [locations lastObject];
    if (location == nil)
        return;
    NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    NSNumber *horizontalAccuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
    NSNumber *altitude = [NSNumber numberWithDouble:location.altitude];
    NSString *my_msg = [NSString stringWithFormat:@"%@ %@ %@ %@", latitude, longitude,
                        horizontalAccuracy, altitude];
    [self.messageChannel sendMessage:my_msg];
    // [self addLocation:location];

}

- (void)addLocation:(nonnull CLLocation *)location {

    // Use very simple way to store some simple data - saving to file
    // In real app if you want to save miltiple data - use databases.
    // We can't save location objects in file, so convert location into
    // dictionaries and save it
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *filePath = [paths.firstObject stringByAppendingPathComponent:@"locations"];
    NSMutableArray *locations = [[NSArray arrayWithContentsOfFile:filePath] mutableCopy];
    if (!locations)
        locations = [NSMutableArray new];
    NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    NSDictionary *locationDictionary = @{@"latitude":latitude, @"longitude":longitude};
    [locations addObject:locationDictionary];
    [locations writeToFile:filePath atomically:YES];
}


@end
