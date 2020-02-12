package ru.unact.repairman;

import android.content.pm.PackageManager;
import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import androidx.core.app.ActivityCompat;
import android.util.Log;
import android.Manifest;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StringCodec;
import io.flutter.view.FlutterView;

public class MainActivity extends FlutterActivity{
  private LocationManager locationManager;
  private static final String CHANNEL = "increment";
  private BasicMessageChannel messageChannel;
  private FlutterView flutterView;

  private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;

  private boolean checkPermissions() {
    int permissionState = ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION);
    return permissionState == PackageManager.PERMISSION_GRANTED;
  }

  private void requestPermissions() {
    ActivityCompat.requestPermissions(this, new String[] { Manifest.permission.ACCESS_FINE_LOCATION },
            REQUEST_PERMISSIONS_REQUEST_CODE);
  }

    @Override
  public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
      switch (requestCode) {
          case REQUEST_PERMISSIONS_REQUEST_CODE: {
              // If request is cancelled, the result arrays are empty.
              if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                  setupLocationManager();
              }
              return;
          }
      }
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    messageChannel = new BasicMessageChannel<>(getFlutterView(), CHANNEL, StringCodec.INSTANCE);

    if (!checkPermissions()) {
        requestPermissions();
    } else {
        setupLocationManager();
    }
  }

  private void setupLocationManager() {
      locationManager = (LocationManager) getSystemService(LOCATION_SERVICE);

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
      Log.v("tag", "get location");
      messageChannel.send(new Double(location.getLatitude()).toString() + " " +
                          new Double(location.getLongitude()).toString() + " " +
                          new Double(location.getAccuracy()).toString() + " " +
                          new Double(location.getAltitude()).toString());
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
