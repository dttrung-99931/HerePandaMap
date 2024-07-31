// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';

import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_panda_map/extensions/map_extensions.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/core/dtos/map_address_component_dto.dart';
import 'package:panda_map/core/models/map_address_component_dto.dart';
import 'package:panda_map/core/models/map_address_location.dart';
import 'package:panda_map/core/models/map_current_location.dart';
import 'package:panda_map/core/models/map_current_location_style.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_mode.dart';
import 'package:panda_map/core/models/map_move_step.dart';
import 'package:panda_map/core/models/map_polyline.dart';
import 'package:panda_map/core/models/map_route.dart';
import 'package:panda_map/core/services/map_api_service.dart';
import 'package:panda_map/panda_map.dart';

class HereRoutingController extends PandaRoutingController {
  HereRoutingController({
    required this.mapController,
  });
  final HerePandaMapController mapController;
  late final MapAPIService _service = PandaMap.mapApiService;
  late final RoutingEngine _routingEngine;

  /// Hold current shoiwing map polyline
  MapPolylinePanda? _routePolyline;

  /// Reference to here polyline that created from [_routePolyline]
  /// Used to delete polyline
  MapPolyline? _herePolylineRef;

  MapRoute? _currentRoute;
  @override
  MapRoute? get currentRoute => _currentRoute;
  MapRoute get _currentRouteNotNull {
    if (_currentRoute == null) {
      throw 'There is no current route. You must start a route before access to this getter';
    }
    return _currentRoute!;
  }

  // TODO:
  @override
  MapMoveStep get currentMoveStep => _currentRouteNotNull.moveSteps.first;

  @override
  Future<void> init() async {
    try {
      _routingEngine = RoutingEngine();
      // TODO: remove listner
      mapController.locationChangedStream.listen(_onLocationChanged);
    } on InstantiationException {
      throw ("Initialization of RoutingEngine failed.");
    }
  }

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
        final List<Maneuver> moveSteps = hereRoute.sections
            .fold([], (steps, sec) => [...steps, ...sec.maneuvers]);
        final MapRoute route = MapRoute(
          polyline: MapPolylinePanda.fromVertices(
            hereRoute.geometry.vertices.map((e) => e.toMapLocation()).toList(),
          ),
          locations: [
            MapAddressLocation(location: start, address: startAddr),
            MapAddressLocation(location: dest, address: destAddr),
          ],
          moveSteps: moveSteps
              .map((Maneuver moveStep) => moveStep.toMoveStep())
              .toList(),
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

  @override // TODO: rename startNavigation
  Future<void> showRoute(MapRoute route) async {
    _currentRoute = route;
    _showRoutePolyline(route.polyline);
    mapController.changeMode(MapMode.navigation);
    mapController.changeCurrentLocationStyle(
      MapCurrentLocationStyle.navigation,
    );
    mapController.focusCurrentLocation();
    notifyListeners();
  }

  void _showRoutePolyline(MapPolylinePanda polyline) {
    _routePolyline = polyline;
    _herePolylineRef = mapController.addPolyline(polyline) as MapPolyline;
  }

  void _removeCurrentRoutePolyline() {
    if (_herePolylineRef != null) {
      mapController.removePolyline(_herePolylineRef!);
      _herePolylineRef = null;
      _routePolyline = null;
    }
  }

  void _onLocationChanged(MapCurrentLocation event) {
    _updateRoutePolyline(event);
  }

  void _updateRoutePolyline(MapCurrentLocation currentLocation) {
    List<MapLocation> polylineLocations =
        List.of(_routePolyline?.vertices ?? []);
    if (polylineLocations.length <= 1) {
      return;
    }

    int len = polylineLocations.length;
    int closestLocationIdx = 0;
    double minDistance =
        currentLocation.distanceInMetters(polylineLocations[0]);
    // TODO: optimize iterate on the first 50 locaitons
    for (int i = 1; i < 10; i++) {
      double distance = currentLocation.distanceInMetters(polylineLocations[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestLocationIdx = i;
      }
    }

    // Handle remove locations behind the current location
    if (closestLocationIdx > 0) {
      log("Remove $closestLocationIdx");
      polylineLocations.removeRange(0, closestLocationIdx);
      log("Remaing ${polylineLocations.length}");
      _removeCurrentRoutePolyline();
      _showRoutePolyline(MapPolylinePanda.fromVertices(polylineLocations));
    }
  }
}
