// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/routing.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/core/models/map_address_location.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_polyline.dart';
import 'package:panda_map/core/models/map_route.dart';
import 'package:panda_map/panda_map.dart';

import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_panda_map/extensions/map_extensions.dart';

class HereRoutingController extends PandaRoutingController {
  HereRoutingController({
    required this.mapController,
  });
  final HerePandaMapController mapController;
  late final RoutingEngine _routingEngine;
  MapRoute? _currentRoute;

  @override
  Future<void> init() async {
    try {
      _routingEngine = RoutingEngine();
    } on InstantiationException {
      throw ("Initialization of RoutingEngine failed.");
    }
  }

  @override
  MapRoute? get currentRoute => _currentRoute;

  @override
  Future<MapRoute?> findRoute({
    required MapLocation start,
    required MapLocation dest,
  }) {
    // Current route will be reset when finding a new route
    _currentRoute = null;

    Waypoint startWaypoint = Waypoint.withDefaults(start.toHereMapCoordinate());
    Waypoint destWaypoint = Waypoint.withDefaults(dest.toHereMapCoordinate());
    List<Waypoint> waypoints = [startWaypoint, destWaypoint];
    BicycleOptions options = BicycleOptions();
    options.routeOptions.enableTolls = true;
    Completer<MapRoute?> completer = Completer();
    _routingEngine.calculateBicycleRoute(
      waypoints,
      options,
      (RoutingError? p0, List<Route>? p1) {
        if (p0 != null) {
          completer.completeError(p0);
          return;
        }

        if (p1 == null || p1.isEmpty) {
          completer.complete(null);
        }
        Route hereRoute = p1!.first;
        MapRoute route = MapRoute(
          polyline: MapPolyline(
            vertices: hereRoute.geometry.vertices
                .map((e) => e.toMapLocation())
                .toList(),
            color: PandaMap.uiOptions.routeColor,
          ),
          locations: [
            MapAddressLocation(location: start, address: '204/12 A3, QL 13'),
            MapAddressLocation(location: dest, address: '19/8 Hồ Văn Huê'),
          ],
        );
        hereRoute.sections.first.arrivalPlace.name;
        completer.complete(route);
      },
    );
    return completer.future;
  }

  @override
  Future<void> showRoute(MapRoute route) async {
    _currentRoute = route;
    mapController.addMapPolyline(route.polyline);
    notifyListeners();
  }
}
