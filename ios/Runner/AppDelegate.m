#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <MapKit/MapKit.h>

@interface AppDelegate()
    @property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    // Setup location tracker accuracy
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    // Distance filter
    self.locationManager.distanceFilter = 50.0;
    
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

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Did update location");
    
    // For real cases we should filter location array by accuracy
    // And check timestamp if you need real time tracking
    // By we don't do it here
    CLLocation *location = [locations lastObject];
    if (location == nil)
        return;
    
    // Save location
    [self addLocation:location];
    
    
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
