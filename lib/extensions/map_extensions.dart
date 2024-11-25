import 'dart:ui';

import 'package:here_panda_map/widgets/custom_current_location_indicator.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/routing.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:panda_map/core/models/map_bounding_box.dart';
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

  LatLng toLatLngPolygonUtil() {
    return LatLng(lat, long);
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
  CustomLocationIndicatorStyle toHereCurrentLocationStyle() {
    switch (this) {
      case MapCurrentLocationStyle.normal:
        return CustomLocationIndicatorStyle.pedestrian;
      case MapCurrentLocationStyle.navigation:
        return CustomLocationIndicatorStyle.navigation;
      case MapCurrentLocationStyle.tracking:
        return CustomLocationIndicatorStyle.motorbikeTracking;
    }
  }
}

extension GeoBoxExt on GeoBox {
  MapBoundingBox toMapBoundingBox() {
    return MapBoundingBox(
      southWestCorner: southWestCorner.toMapLocation(),
      northEastCorner: northEastCorner.toMapLocation(),
    );
  }
}

extension MapBoundingBoxExt on MapBoundingBox {
  GeoBox toGeoBox() {
    return GeoBox(
      southWestCorner.toHereMapCoordinate(),
      northEastCorner.toHereMapCoordinate(),
    );
  }
}

extension OffsetExt on Offset {
  Point2D toPoint2D() {
    return Point2D(dx, dy);
  }
}

extension SizeExt on Size {
  Size2D toSize2D() {
    return Size2D(width, height);
  }
}
