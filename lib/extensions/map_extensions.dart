import 'package:here_sdk/core.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_polyline.dart';

extension MapLocationExt on MapLocation {
  GeoCoordinates toHereMapCoordinate() {
    return GeoCoordinates(lat, long);
  }
}

extension GeoCoordinatesExt on GeoCoordinates {
  MapLocation toMapLocation() {
    return MapLocation(lat: latitude, long: longitude);
  }
}

extension MapPolylineExt on MapPolyline {
  GeoPolyline toHereMapGeoPolyline() {
    return GeoPolyline(vertices.map((e) => e.toHereMapCoordinate()).toList());
  }
}
