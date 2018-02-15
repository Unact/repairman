package com.yourcompany.repairman;

import android.content.pm.PackageManager;
import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.support.v4.app.ActivityCompat;
import android.util.Log;
import android.Manifest;

public class MainActivity extends FlutterActivity{
  private LocationManager locationManager;

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
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    if (!checkPermissions()) {
      requestPermissions();
    }
    locationManager = (LocationManager) getSystemService(LOCATION_SERVICE);

    locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
            1000 * 10, 10, locationListener);
    locationManager.requestLocationUpdates(
            LocationManager.NETWORK_PROVIDER, 1000 * 10, 10,
            locationListener);
  }

  private LocationListener locationListener = new LocationListener() {

    @Override
    public void onLocationChanged(Location location) {
      //showLocation(location);
      Log.v("tag", "get location");
    }

    @Override
    public void onProviderDisabled(String provider) {
      //checkEnabled();
    }

    @Override
    public void onProviderEnabled(String provider) {
      //checkEnabled();
      //showLocation(locationManager.getLastKnownLocation(provider));
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {
/*    if (provider.equals(LocationManager.GPS_PROVIDER)) {
        tvStatusGPS.setText("Status: " + String.valueOf(status));
      } else if (provider.equals(LocationManager.NETWORK_PROVIDER)) {
        tvStatusNet.setText("Status: " + String.valueOf(status));
      }*/
    }
  };

}
