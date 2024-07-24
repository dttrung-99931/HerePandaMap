import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:panda_map/core/models/map_current_location_style.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_move_action.dart';
import 'package:panda_map/core/models/map_move_step.dart';
import 'package:panda_map/core/models/map_polyline.dart';

part 'navigation_extensions.dart';

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

extension MapPolylineExt on MapPolylinePanda {
  GeoPolyline toHereMapGeoPolyline() {
    return GeoPolyline(vertices.map((e) => e.toHereMapCoordinate()).toList());
  }
}

extension MapCurrentLocationStyleExt on MapCurrentLocationStyle {
  LocationIndicatorIndicatorStyle toHereCurrentLocationStyle() {
    switch (this) {
      case MapCurrentLocationStyle.normal:
        return LocationIndicatorIndicatorStyle.pedestrian;
      case MapCurrentLocationStyle.navigation:
        return LocationIndicatorIndicatorStyle.navigation;
    }
  }
}
