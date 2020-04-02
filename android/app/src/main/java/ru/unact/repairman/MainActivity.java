package ru.unact.repairman;

import android.content.pm.PackageManager;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import androidx.core.app.ActivityCompat;
import android.Manifest;
import com.yandex.mapkit.MapKitFactory;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "ru.unact.repairman/location";
  private MethodChannel methodChannel;

  private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;

  private void requestPermissions() {
    ActivityCompat.requestPermissions(
      this,
      new String[] { Manifest.permission.ACCESS_FINE_LOCATION },
      REQUEST_PERMISSIONS_REQUEST_CODE
    );
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
    switch (requestCode) {
      case REQUEST_PERMISSIONS_REQUEST_CODE: {
        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          setupLocationManager();
        }
        return;
      }
      default: {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
      }
    }
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    MapKitFactory.setApiKey(BuildConfig.YANDEX_API_KEY);

    methodChannel = new MethodChannel(getFlutterView(), CHANNEL);
    methodChannel.setMethodCallHandler(
      (call, result) -> {
        switch (call.method) {
          default:
            result.notImplemented();
            break;
        }
      }
    );

    setupLocationManager();

    GeneratedPluginRegistrant.registerWith(this);
  }

  private void setupLocationManager() {
    int permissionState = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION);
    LocationManager locationManager = (LocationManager) getSystemService(LOCATION_SERVICE);

    if (permissionState != PackageManager.PERMISSION_GRANTED) {
      requestPermissions();
      return;
    }

    locationManager.requestLocationUpdates(
      LocationManager.GPS_PROVIDER,
      1000 * 10,
      10,
      locationListener
    );
    locationManager.requestLocationUpdates(
      LocationManager.NETWORK_PROVIDER,
      1000 * 10,
      10,
      locationListener
    );
  }

  private LocationListener locationListener = new LocationListener() {
    @Override
    public void onLocationChanged(Location location) {
      Map<String, Object> arguments = new HashMap<>();

      arguments.put("latitude", location.getLatitude());
      arguments.put("longitude", location.getLongitude());
      arguments.put("accuracy", location.getAccuracy());
      arguments.put("altitude", location.getAltitude());

      methodChannel.invokeMethod("onLocationChanged", arguments);
    }

    @Override
    public void onProviderDisabled(String provider) {
    }

    @Override
    public void onProviderEnabled(String provider) {
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {
    }
  };
}
