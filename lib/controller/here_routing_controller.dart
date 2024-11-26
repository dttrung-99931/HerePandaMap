// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';
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
import 'package:panda_map/utils/constants.dart';

class HereRoutingController extends PandaRoutingController {
  HereRoutingController({
    required this.mapController,
    required this.service,
  });

  final HerePandaMapController mapController;
  final MapAPIService service;

  /// Engine for handling routing
  late final RoutingEngine _routingEngine;
  final CarOptions _carRouteOptions = CarOptions()
    ..routeOptions.enableTolls = false // Include trạm thu phí
    ..routeOptions.enableRouteHandle =
        true; // Support refreshRoute on location changed to get remaining length

  @override
  PandaRoutingStatus get status => _status;
  PandaRoutingStatus _status = PandaRoutingStatus.noRouting;

  /// route used in PandaMap plugin
  MapRoute? _currentRoute;

  /// Route in [PandaRoutingStatus.previewRoute]
  MapRoute? _previewRoute;
  @override
  MapRoute? get previewRoute => _previewRoute;

  /// Here polyline of current route
  /// Reference to here polyline that created from [_routePolyline]
  /// Used to delete polyline
  MapPolyline? _herePolylineRef;

  /// Polyline of current route
  MapPolylinePanda? _routePolyline;

  StreamSubscription? _locationChangedSub;

  // TODO:
  @override
  MapMoveStep get currentMoveStep => _currentRouteNotNull.moveSteps.first;

  @override
  MapRoute? get currentRoute => _currentRoute;

  @override
  bool get isNavigating => _currentRoute != null;

  @override
  Stream<MapCurrentLocation> get movingLocationStream =>
      _movingLocationStream.stream;
  final StreamController<MapCurrentLocation> _movingLocationStream =
      StreamController<MapCurrentLocation>.broadcast();

  @override
  int get remainingRouteLengthInMetter => _remainingRouteLengthInMetter;
  int _remainingRouteLengthInMetter = 0;

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
    final startWaypoint = Waypoint.withDefaults(start.toHereMapCoordinate());
    final destWaypoint = Waypoint.withDefaults(dest.toHereMapCoordinate());
    final List<Waypoint> waypoints = [startWaypoint, destWaypoint];
    Completer<List<Route>> completer = Completer();
    _routingEngine.calculateCarRoute(
      waypoints,
      _carRouteOptions,
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
    _status = PandaRoutingStatus.previewRoute;
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
    notifyListeners();
  }

  @override
  Future<void> startNavigation(MapRoute route) async {
    _status = PandaRoutingStatus.navigating;
    _currentRoute = route;
    _previewRoute = null;
    notifyListeners();
    await mapController.changeCurrentLocationStyle(navigatingLocationStyle);
    mapController.focusCurrentLocation();
    mapController.zoom(Constants.defaultZoomLevel);
    _locationChangedSub?.cancel();
    _locationChangedSub = mapController.locationChangedStream.listen(
      _onLocationChanged,
    );
  }

  @override
  Future<void> stopNavigation() async {
    mapController.changeMode(MapMode.normal);
    mapController.changeCurrentLocationStyle(MapCurrentLocationStyle.normal);
    _status = PandaRoutingStatus.noRouting;
    _currentRoute = null;
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
    mapController.focusCurrentLocation(currentLocation: current);
    if (_currentRoute != null) {
      if (navigatingLocationStyle == MapCurrentLocationStyle.navigation) {
        mapController.rotateMap(current, current.bearingDegrees);
      }
      const int toleranceInMetters = Constants.toleranceInMetters; // sai so
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
        _remainingRouteLengthInMetter =
            await _calculateRemainingRouteLength(current);
        _movingLocationStream.add(current);
      } else {
        // TODO: hanlde re-route

        // TODO: handle movingLocationStream on re-route. Currently treat as normal locaiton changed
        _movingLocationStream.add(current);
      }
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
      lengthInMeters: hereRoute.lengthInMeters,
      durationInMinutes: hereRoute.duration.inMinutes,
      sdkRoute: hereRoute,
    );
    return route;
  }

  Future<MapAddressComponent?> _getAddressByGeo(MapLocation location) async {
    final MapAddressComponentDto? addr =
        await service.getAddressByGeo(location);
    return addr != null ? MapAddressComponent.fromDto(addr) : null;
  }

  Future<void> _showUpdateRoutePolyline(MapPolylinePanda polyline) async {
    // Keep old polyline to remove
    MapPolyline? removedPolyline = _herePolylineRef;
    // Show new polyline before removing to improve lagging when updating polyline
    _showRoutePolyline(polyline);
    if (removedPolyline != null) {
      mapController.removePolyline(removedPolyline);
    }
  }

  Future<int> _calculateRemainingRouteLength(
      MapCurrentLocation location) async {
    final updatedStart = Waypoint.withDefaults(location.toHereMapCoordinate());
    Completer<List<Route>> completer = Completer();
    _routingEngine.refreshRoute(
      _currentRoute!.sdkRoute.routeHandle!,
      updatedStart,
      RefreshRouteOptions.withCarOptions(_carRouteOptions),
      (RoutingError? error, List<Route>? routes) async {
        _onRouteResult(
          error: error,
          routes: routes,
          routesResultCompleter: completer,
          start: location,
          dest: _destLocation,
        );
      },
    );

    List<Route> routes = [];
    try {
      routes = await completer.future;
    } on RoutingError catch (error) {
      if (error == RoutingError.couldNotMatchOrigin) {
        // TODO:re-route
      }
    }

    if (routes.isNotEmpty) {
      // TODO: keep updated route
      Route updatedRoute = routes.first;
      log('Refresh route successed, renmaming length = ${updatedRoute.lengthInMeters}');
      return updatedRoute.lengthInMeters;
    } else {
      log('Refresh route return empty routes');
      return -1;
    }
  }
}
