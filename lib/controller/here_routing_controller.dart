// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/routing.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/core/dtos/map_address_component_dto.dart';
import 'package:panda_map/core/models/map_address_component_dto.dart';
import 'package:panda_map/core/models/map_address_location.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_mode.dart';
import 'package:panda_map/core/models/map_polyline.dart';
import 'package:panda_map/core/models/map_route.dart';
import 'package:panda_map/core/services/map_api_service.dart';
import 'package:panda_map/panda_map.dart';

import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_panda_map/extensions/map_extensions.dart';

class HereRoutingController extends PandaRoutingController {
  HereRoutingController({
    required this.mapController,
  });
  final HerePandaMapController mapController;
  late final MapAPIService _service = PandaMap.mapApiService;
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

    final startWaypoint = Waypoint.withDefaults(start.toHereMapCoordinate());
    final destWaypoint = Waypoint.withDefaults(dest.toHereMapCoordinate());
    final waypoints = [startWaypoint, destWaypoint];
    final options = BicycleOptions();
    options.routeOptions.enableTolls = true;
    Completer<MapRoute?> completer = Completer();
    _routingEngine.calculateBicycleRoute(
      waypoints,
      options,
      (RoutingError? p0, List<Route>? p1) async {
        if (p0 != null) {
          completer.completeError(p0);
          return;
        }

        if (p1 == null || p1.isEmpty) {
          completer.complete(null);
        }
        final Route hereRoute = p1!.first;
        final MapAddressComponent? startAddr = await _getAddressByGeo(start);
        final MapAddressComponent? destAddr = await _getAddressByGeo(dest);
        final MapRoute route = MapRoute(
          polyline: MapPolyline(
            vertices: hereRoute.geometry.vertices
                .map((e) => e.toMapLocation())
                .toList(),
            color: PandaMap.uiOptions.routeColor,
          ),
          locations: [
            MapAddressLocation(location: start, address: startAddr),
            MapAddressLocation(location: dest, address: destAddr),
          ],
        );
        hereRoute.sections.first.arrivalPlace.name;
        completer.complete(route);
      },
    );
    return completer.future;
  }

  Future<MapAddressComponent?> _getAddressByGeo(MapLocation location) async {
    final MapAddressComponentDto? addr =
        await _service.getAddressByGeo(location);
    return addr != null ? MapAddressComponent.fromDto(addr) : null;
  }

  @override
  Future<void> showRoute(MapRoute route) async {
    _currentRoute = route;
    mapController.addMapPolyline(route.polyline);
    mapController.changeMode(MapMode.navigation);
    notifyListeners();
  }
}
