// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_panda_map/extensions/map_extensions.dart';
import 'package:here_panda_map/here_map_options.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/core/models/map_address_location.dart';
import 'package:panda_map/core/models/map_current_location.dart';
import 'package:panda_map/core/models/map_current_location_style.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_mode.dart';
import 'package:panda_map/core/models/map_move_step.dart';
import 'package:panda_map/core/models/map_polyline.dart';
import 'package:panda_map/core/models/map_route.dart';
import 'package:panda_map/panda_map.dart';

class HereRoutingController extends PandaRoutingController {
  HereRoutingController({
    required this.mapController,
  });

  final HerePandaMapController mapController;
  late final RoutingEngine _routingEngine;

  /// Hold current shoiwing map polyline
  MapPolylinePanda? _routePolyline;

  /// Reference to here polyline that created from [_routePolyline]
  /// Used to delete polyline
  MapPolyline? _herePolylineRef;
  MapRoute? _currentRoute; // route from PandaMap plugin
  Route? _currentHereRoute; // route from heremap sdk
  final BicycleOptions _bicycleoptions = BicycleOptions()
    ..routeOptions.enableTolls = false // Include trạm thu phí
    ..routeOptions.enableRouteHandle =
        true; // Support refreshRoute on location changed
  StreamSubscription? _locationChangedSub;

  @override
  bool get isNavigating => _currentRoute != null;

  // TODO:
  @override
  MapMoveStep get currentMoveStep => _currentRouteNotNull.moveSteps.first;

  @override
  MapRoute? get currentRoute => _currentRoute;
  MapRoute get _currentRouteNotNull {
    if (_currentRoute == null) {
      throw 'There is no current route. You must start a route before access to this getter';
    }
    return _currentRoute!;
  }

  MapLocation get _destLocation => _currentRoute!.locations.last.location;

  @override
  Future<MapRoute?> findRoute({
    required MapLocation start,
    required MapLocation dest,
  }) {
    // Current route will be reset when finding a new route
    _currentRoute = null;
    _currentHereRoute = null;
    final startWaypoint = Waypoint.withDefaults(start.toHereMapCoordinate());
    final destWaypoint = Waypoint.withDefaults(dest.toHereMapCoordinate());
    final List<Waypoint> waypoints = [startWaypoint, destWaypoint];
    Completer<MapRoute?> completer = Completer();
    _routingEngine.calculateBicycleRoute(
      waypoints,
      _bicycleoptions,
      (RoutingError? error, List<Route>? routes) async {
        _onRouteResult(
          error: error,
          routes: routes,
          completer: completer,
          start: start,
          dest: dest,
        );
      },
    );
    return completer.future;
  }

  @override
  Future<void> init() async {
    try {
      final options = (PandaMap.options as HerePandaMapOptions);

      /// SDKNativeEngine.sharedInstance need to be initilized before init RoutingEngine
      /// Although SDKNativeEngine.sharedInstance was init in [HerePandaMapController.init]
      /// But for unknown reason, sometime it's still not init here and init RoutingEngine got exception
      if (SDKNativeEngine.sharedInstance == null) {
        String accessKeyId = options.mapAPIKeyId;
        String accessKeySecret = options.mapAPIKey;
        SDKOptions sdkOptions =
            SDKOptions.withAccessKeySecret(accessKeyId, accessKeySecret);
        await SDKNativeEngine.makeSharedInstance(sdkOptions);
      }

      _routingEngine = RoutingEngine.withConnectionSettings(
        RoutingConnectionSettings()
          ..initialConnectionTimeout = const Duration(seconds: 30),
      );
    } on InstantiationException catch (e) {
      throw ("Initialization of RoutingEngine failed. ${e.error}");
    }
  }

  @override
  Future<void> startNavigation(MapRoute route) async {
    _currentRoute = route;
    mapController.changeMode(MapMode.navigation);
    mapController.changeCurrentLocationStyle(
      MapCurrentLocationStyle.navigation,
    );
    _locationChangedSub = mapController.locationChangedStream.listen(
      _onLocationChanged,
    );
  }

  @override
  Future<void> stopNavigation() async {
    _currentRoute = null;
    _currentHereRoute = null;
    _locationChangedSub?.cancel();
  }

  @override
  Future<void> showRoute(MapRoute route) async {
    mapController.focusCurrentLocation();
    await Future.delayed(const Duration(milliseconds: 300));
    _showRoutePolyline(route.polyline);
  }

  Future<void> _onLocationChanged(MapCurrentLocation current) async {
    await mapController.focusCurrentLocation(
      currentLocation: current,
      animate: false,
    );
    if (_currentRoute != null) {
      _updateRoute(current);
    }
  }

  void _onRouteResult({
    required RoutingError? error,
    required List<Route>? routes,
    required Completer<MapRoute?> completer,
    required MapLocation start,
    required MapLocation dest,
  }) {
    if (error != null) {
      completer.completeError(error);
      return;
    }
    if (routes == null || routes.isEmpty) {
      completer.complete(null);
    }

    final Route hereRoute = routes!.first;
    _currentHereRoute = hereRoute;
    // final MapAddressComponent? startAddr = await _getAddressByGeo(start);
    // final MapAddressComponent? destAddr = await _getAddressByGeo(dest);
    final List<Maneuver> moveSteps = hereRoute.sections
        .fold([], (steps, sec) => [...steps, ...sec.maneuvers]);
    final MapRoute route = MapRoute(
      polyline: MapPolylinePanda.fromVertices(
        hereRoute.geometry.vertices.map((e) => e.toMapLocation()).toList(),
      ),
      locations: [
        MapAddressLocation(location: start, address: null),
        MapAddressLocation(location: dest, address: null),
      ],
      moveSteps:
          moveSteps.map((Maneuver moveStep) => moveStep.toMoveStep()).toList(),
    );
    completer.complete(route);
  }

  void _removeCurrentRoutePolyline() {
    if (_herePolylineRef != null) {
      mapController.removePolyline(_herePolylineRef!);
      _herePolylineRef = null;
      _routePolyline = null;
    }
  }

  void _showRoutePolyline(MapPolylinePanda polyline) {
    _routePolyline = polyline;
    _herePolylineRef = mapController.addPolyline(polyline) as MapPolyline;
  }

  Future<void> _updateRoute(MapCurrentLocation currentLocation) async {
    Completer<MapRoute?> completer = Completer();
    _routingEngine.refreshRoute(
      _currentHereRoute!.routeHandle!,
      Waypoint(currentLocation.toHereMapCoordinate()),
      RefreshRouteOptions.withBicycleOptions(_bicycleoptions),
      (RoutingError? error, List<Route>? routes) {
        _onRouteResult(
          error: error,
          routes: routes,
          completer: completer,
          start: currentLocation,
          dest: _destLocation,
        );
      },
    );

    MapRoute? updatedRoute;
    try {
      updatedRoute = await completer.future;
    } on RoutingError catch (error) {
      if (error == RoutingError.couldNotMatchOrigin) {
        // TODO: re-route
      }
    }
    if (updatedRoute != null) {
      _updateRoutePolyline(updatedRoute);
    }
  }

  Future<void> _updateRoutePolyline(MapRoute route) async {
    _currentRoute = route;
    if (_routePolyline != null) {
      _removeCurrentRoutePolyline();
    }
    _showRoutePolyline(route.polyline);
  }

  @override
  void dispose() {
    _locationChangedSub?.cancel();
    super.dispose();
  }
}
