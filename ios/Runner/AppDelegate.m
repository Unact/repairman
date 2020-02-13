#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <YandexMapKit/YMKMapKit.h>
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
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"env" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:resourcePath];

    [YMKMapKit setApiKey: dict[@"YANDEX_API_KEY"]];

    self.messageChannel = [ FlutterBasicMessageChannel messageChannelWithName:channel
                            binaryMessenger:self.window.rootViewController
                            codec:[FlutterStringCodec sharedInstance]];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 5.0f;
    self.locationManager.delegate = self;

    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    // For iOS9 we have to call this method if we want to receive location updates in background mode
    if([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }

    [self.locationManager requestAlwaysAuthorization];

    [self.locationManager startUpdatingLocation];

    [GeneratedPluginRegistrant registerWithRegistry:self];

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"Go to terminate");
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Did update location!");

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
}

@end
