// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ui';

import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_panda_map/extensions/map_extensions.dart';
import 'package:here_panda_map/here_map_options.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
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

enum HereRoutingStatus {
  previewRoute,
  navigating,
  noRouting,
}

class HereRoutingController extends PandaRoutingController {
  HereRoutingController({
    required this.mapController,
    required this.service,
  });

  final HerePandaMapController mapController;
  final MapAPIService service;

  /// Engine for handling routing
  late final RoutingEngine _routingEngine;
  final BicycleOptions _bicycleoptions = BicycleOptions()
    ..routeOptions.enableTolls = false // Include trạm thu phí
    ..routeOptions.enableRouteHandle =
        true; // Support refreshRoute on location changed

  HereRoutingStatus get status => _status;
  HereRoutingStatus _status = HereRoutingStatus.noRouting;

  /// route from heremap sdk, mapped from [_currentRoute]
  Route? _currentHereRoute;

  /// route used in PandaMap plugin
  MapRoute? _currentRoute;

  /// Route in [HereRoutingStatus.previewRoute]
  MapRoute? _previewRoute;
  MapRoute get previewRoute => _previewRoute!;

  /// Here polyline of current route
  /// Reference to here polyline that created from [_routePolyline]
  /// Used to delete polyline
  MapPolyline? _herePolylineRef;

  /// Polyline of current route
  MapPolylinePanda? _routePolyline;

  bool _isRouteUpdating = false;
  StreamSubscription? _locationChangedSub;

  // TODO:
  @override
  MapMoveStep get currentMoveStep => _currentRouteNotNull.moveSteps.first;

  @override
  MapRoute? get currentRoute => _currentRoute;

  @override
  bool get isNavigating => _currentRoute != null;

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
  void dispose() {
    _locationChangedSub?.cancel();
    super.dispose();
  }

  @override
  Future<MapRoute?> findRoute({
    required MapLocation start,
    required MapLocation dest,
  }) async {
    // Current route will be reset when finding a new route
    _previewRoute = null;
    _currentRoute = null;
    _currentHereRoute = null;
    final startWaypoint = Waypoint.withDefaults(start.toHereMapCoordinate());
    final destWaypoint = Waypoint.withDefaults(dest.toHereMapCoordinate());
    final List<Waypoint> waypoints = [startWaypoint, destWaypoint];
    Completer<List<Route>> completer = Completer();
    _routingEngine.calculateBicycleRoute(
      waypoints,
      _bicycleoptions,
      (RoutingError? error, List<Route>? routes) async {
        _onRouteResult(
          error: error,
          routes: routes,
          routesResultCompleter: completer,
          start: start,
          dest: dest,
        );
      },
    );
    List<Route> routes = await completer.future;
    return _toMapRoute(routes.first, start, dest);
  }

  @override
  Future<void> showRoute(MapRoute route) async {
    _status = HereRoutingStatus.previewRoute;
    _previewRoute = route;
    mapController.changeMode(MapMode.navigation);
    mapController.focusCurrentLocation();
    await Future.delayed(const Duration(milliseconds: 300));
    mapController.lookAtAreaInsideRectangle(
      area: route.boundingBox,
      topLeftRect: Offset(
        mapController.mapViewPort.width * 0.08,
        mapController.mapViewPort.height * 0.08,
      ),
      rectSize: Size(
        // 0.84 = 2*paddingVerticalRatio
        mapController.mapViewPort.width * 0.84,
        // 0.84 = 2*paddingHorzRatio
        mapController.mapViewPort.height * 0.84,
      ),
    );
    _showRoutePolyline(route.polyline);
  }

  @override
  Future<void> startNavigation(MapRoute route) async {
    _status = HereRoutingStatus.navigating;
    _currentRoute = route;
    _previewRoute = null;
    notifyListeners();
    mapController.changeCurrentLocationStyle(
      MapCurrentLocationStyle.navigation,
    );
    _locationChangedSub?.cancel();
    _locationChangedSub = mapController.locationChangedStream.listen(
      _onLocationChanged,
    );
  }

  @override
  Future<void> stopNavigation() async {
    mapController.changeMode(MapMode.normal);
    _status = HereRoutingStatus.noRouting;
    _currentRoute = null;
    _currentHereRoute = null;
    _locationChangedSub?.cancel();
  }

  MapRoute get _currentRouteNotNull {
    if (_currentRoute == null) {
      throw 'There is no current route. You must start a route before access to this getter';
    }
    return _currentRoute!;
  }

  MapLocation get _destLocation => _currentRoute!.locations.last.location;

  Future<void> _onLocationChanged(MapCurrentLocation current) async {
    // focusCurrentLocation, rotateMap & updateRoute in the same time.
    // No need to wait each other done
    mapController.focusCurrentLocation(
      currentLocation: current,
      animate: false,
    );
    if (_currentRoute != null) {
      mapController.rotateMap(current, current.bearingDegrees);
      const int toleranceInMetters = 10; // sai so
      int nearestPointIdx = PolygonUtil.locationIndexOnPath(
        current.toLatLngPolygonUtil(),
        _routePolyline!.vertices
            .map((MapLocation point) => point.toLatLngPolygonUtil())
            .toList(),
        false,
        tolerance: toleranceInMetters,
      );
      if (nearestPointIdx != -1) {
        // Remove passed vertices
        List<MapLocation> updatedVertices = _routePolyline!.vertices
          ..removeRange(0, nearestPointIdx + 1);
        // Add currentLocation as new a vertice if the space is enough large.
        // Always adding current location may causing the polyline is incorrect
        // in case of current location is outside of the polyline
        if (updatedVertices.isNotEmpty &&
            updatedVertices.first.distanceInMetters(current) >=
                toleranceInMetters) {
          updatedVertices.insert(0, current);
        }
        _routePolyline = _routePolyline?.copyWith(vertices: updatedVertices);
        _showUpdateRoutePolyline(_routePolyline!);
      } else {
        // TODO: hanlde re-route
      }
      // _updateCurrentRoute(current);
    }
  }

  /// Handle routes results
  /// complete [routesResultCompleter] when success,
  /// otherwise [routesResultCompleter]completeError with error message
  void _onRouteResult({
    required RoutingError? error,
    required List<Route>? routes,
    required MapLocation start,
    required MapLocation dest,
    required Completer<List<Route>> routesResultCompleter,
  }) {
    if (error != null) {
      routesResultCompleter.completeError(error);
      return;
    }
    if (routes == null || routes.isEmpty) {
      routesResultCompleter.completeError('Cannot found any routes');
    }
    routesResultCompleter.complete(routes);
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

  /// Update route with latest current location
  /// If _updateCurrentRoute is excuting, other _updateCurrentRoute call will be ignored
  Future<void> _updateCurrentRoute(MapCurrentLocation currentLocation) async {
    if (_isRouteUpdating) {
      return;
    }
    _isRouteUpdating = true;
    Completer<List<Route>> completer = Completer();
    _routingEngine.refreshRoute(
      _currentHereRoute!.routeHandle!,
      Waypoint(currentLocation.toHereMapCoordinate()),
      RefreshRouteOptions.withBicycleOptions(_bicycleoptions),
      (RoutingError? error, List<Route>? routes) {
        _onRouteResult(
          error: error,
          routes: routes,
          routesResultCompleter: completer,
          start: currentLocation,
          dest: _destLocation,
        );
      },
    );
    try {
      List<Route> updatedRoutes = await completer.future;
      _currentHereRoute = updatedRoutes.first;
      _currentRoute = await _toMapRoute(
        updatedRoutes.first,
        currentLocation,
        _destLocation,
      );
      _showUpdateRoutePolyline(_currentRoute!.polyline);
    } on RoutingError catch (error) {
      if (error == RoutingError.couldNotMatchOrigin) {
        // TODO: re-route
      }
    }
    _isRouteUpdating = false;
  }

  /// Map Route (here route) to MapRoute (route defiend by PandaMap plugin)
  /// MapRoute includes polyline, locations (start, dest), move steps
  Future<MapRoute> _toMapRoute(
    Route hereRoute,
    MapLocation start,
    MapLocation dest,
  ) async {
    // TODO: get from server instead to optimize re-geocoding requests
    final MapAddressComponent? startAddr = await _getAddressByGeo(start);
    final MapAddressComponent? destAddr = await _getAddressByGeo(dest);
    final List<Maneuver> moveSteps = hereRoute.sections.fold(
      [],
      (steps, sec) => [...steps, ...sec.maneuvers],
    );
    final MapRoute route = MapRoute(
      polyline: MapPolylinePanda.fromVertices(
        hereRoute.geometry.vertices.map((e) => e.toMapLocation()).toList(),
      ),
      locations: [
        MapAddressLocation(location: start, address: startAddr),
        MapAddressLocation(location: dest, address: destAddr)
      ],
      moveSteps:
          moveSteps.map((Maneuver moveStep) => moveStep.toMoveStep()).toList(),
      boundingBox: hereRoute.boundingBox.toMapBoundingBox(),
    );
    return route;
  }

  Future<MapAddressComponent?> _getAddressByGeo(MapLocation location) async {
    final MapAddressComponentDto? addr =
        await service.getAddressByGeo(location);
    return addr != null ? MapAddressComponent.fromDto(addr) : null;
  }

  Future<void> _showUpdateRoutePolyline(MapPolylinePanda polyline) async {
    if (_routePolyline != null) {
      _removeCurrentRoutePolyline();
    }
    _showRoutePolyline(polyline);
  }
}
