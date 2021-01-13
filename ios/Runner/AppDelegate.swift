import UIKit
import Flutter
import MapKit
import YandexMapsMobile

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var locationListener: LocationListener!
  private var locationManager: CLLocationManager!
  private var methodChannel: FlutterMethodChannel!
  private let channel = "ru.unact.repairman/location"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let resourcePath = Bundle.main.path(forResource: "env", ofType: "plist")!
    let dict = NSDictionary.init(contentsOfFile: resourcePath)!
    YMKMapKit.setApiKey((dict.value(forKeyPath: "YANDEX_API_KEY") as! String))

    methodChannel = FlutterMethodChannel(
      name: channel,
      binaryMessenger: controller.binaryMessenger
    )
    methodChannel.setMethodCallHandler({ (call, result) in
      switch(call.method) {
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    locationListener = LocationListener.init(channel: methodChannel)
    locationManager = CLLocationManager.init()
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 5.0
    locationManager.delegate = locationListener
    locationManager.requestAlwaysAuthorization()
    locationManager.startUpdatingLocation()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    locationManager.stopUpdatingLocation()
  }
  internal class LocationListener: NSObject, CLLocationManagerDelegate {
    private var methodChannel: FlutterMethodChannel!

    public required init(channel: FlutterMethodChannel) {
      self.methodChannel = channel
      super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      let location = locations.last
      if (location == nil) {
        return
      }

      let arguments: [String:Any?] = [
        "latitude": location!.coordinate.latitude,
        "longitude": location!.coordinate.longitude,
        "accuracy": location!.horizontalAccuracy,
        "altitude": location!.altitude
      ]

      methodChannel.invokeMethod("onLocationChanged", arguments: arguments)
    }
  }
}
