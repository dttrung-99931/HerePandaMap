import 'dart:async';
import 'dart:developer';

import 'package:here_panda_map/here_map_options.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:location_platform_interface/location_platform_interface.dart';
import 'package:panda_map/assets/assets.dart';
import 'package:panda_map/core/controllers/panda_map_controller.dart';
import 'package:panda_map/core/models/map_lat_lng.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/utils/asset_utils.dart';

class HerePandaMapController extends PandaMapController {
  HerePandaMapController();

  // final Set<Marker> markers = <Marker>{};
  // final Set<Circle> circles = <Circle>{};
  Completer<HereMapController> _controllerCompleter = Completer();

  // MapType get mapType => MapType.values[currentMapTypeIndex];

  MapMarker? _currentLocationMarker;

  final int _currentMapTypeIndex = 1;
  LocationIndicator? _locationIndicator;

  @override
  Future<void> initMap(covariant HerePandaMapOptions options) async {
    SdkContext.init(IsolateOrigin.main);
    String accessKeyId = options.mapAPIKeyId;
    String accessKeySecret = options.mapAPIKey;
    SDKOptions sdkOptions =
        SDKOptions.withAccessKeySecret(accessKeyId, accessKeySecret);
    try {
      await SDKNativeEngine.makeSharedInstance(sdkOptions);
    } on InstantiationException {
      throw Exception("Failed to initialize the HERE SDK.");
    }
  }

  @override
  void dispose() {
    SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    super.dispose();
  }

  @override
  void onLocationChanged(LocationData event) {
    focusMapTo(MapLocation.fromLocationData(event));
    _locationIndicator?.updateLocation(Location.withCoordinates(
      GeoCoordinates(event.latitude!, event.longitude!),
    ));
  }

  @override
  void addMarker(MapLatLng latlng) {
    // Marker marker = Marker(
    //     markerId: MarkerId(latlng.toString()),
    //     position: latlng.toGoogleLatLng(),);
    // markers.add(marker);
    notifyListeners();
  }

  @override
  void addRandomCircle(MapLatLng latlng) {
    // Circle circle = Circle(
    //     circleId: CircleId(latlng.toString()),
    //     fillColor: Colors.purple[100 * (1 + math.Random().nextInt(8))]!,
    //     center: latlng.toGoogleLatLng(),
    //     strokeWidth: 0,
    //     radius: 20.toDouble() * (1 + math.Random().nextInt(8)));

    // circles.add(circle);
    notifyListeners();
  }

  @override
  void changeMapType() {
    // _currentMapTypeIndex++;
    // if (currentMapTypeIndex == MapType.values.length) {
    //   _currentMapTypeIndex = 0;
    // }
    notifyListeners();
  }

  @override
  Future<void> focusCurrentLocation({bool animate = true}) async {
    MapLocation? location = await mapService.getCurrentLocation();
    if (location != null) {
      focusMapTo(location);
      // Run by contorl to mark sure called after mapInint
      control((_) async {
        _locationIndicator?.updateLocation(
          Location.withCoordinates(location.toHereMapCoordinate()),
        );
      });
    } else {
      log('Google map: FInd location failed');
    }
  }

  @override
  Future<void> focusMapTo(MapLocation location, {bool animate = true}) async {
    return control((HereMapController controller) async {
      MapCameraAnimation amim = MapCameraAnimationFactory.flyTo(
        GeoCoordinatesUpdate(location.lat, location.long),
        1,
        const Duration(milliseconds: 800),
      );
      controller.camera.startAnimation(amim);
    });
  }

  bool get isMapInitilized => _controllerCompleter.isCompleted;

  late Future<HereMapController> controllerFuture = _controllerCompleter.future;

  int get currentMapTypeIndex => _currentMapTypeIndex;
  HereMapController? _controller;

  void onMapCreated(HereMapController controller) {
    load(() async {
      // onMapCreated may be called many times by MapScreen due to back to home screen
      if (_controllerCompleter.isCompleted) {
        _controllerCompleter = Completer();
      }
      _controllerCompleter.complete(controller);
      _controller = controller;
      // Setup current location indicator
      _locationIndicator?.disable();
      _locationIndicator = LocationIndicator()
        ..locationIndicatorStyle = LocationIndicatorIndicatorStyle.pedestrian;
      _locationIndicator?.enable(controller);
      await focusCurrentLocation(animate: false);

      // Load map
      Completer<bool> loadComplete = Completer<bool>();
      controller.mapScene.loadSceneForMapScheme(
        MapScheme.normalDay,
        (MapError? error) async {
          if (error != null) {
            log('Map scene not loaded. MapError: ${error.toString()}');
            return;
          }
          loadComplete.complete(true);
        },
      );

      // Tracking current location
    });
  }

  Future<void> control(
    Future<void> Function(HereMapController controller) action,
  ) async {
    HereMapController controller = _controller ?? await controllerFuture;
    await action(controller);
  }

  // Add marker
  Future<void> _addCurrentLocationMarker(MapLocation location) async {
    await control(
      (controller) async {
        if (_currentLocationMarker != null) {
          controller.mapScene.removeMapMarker(_currentLocationMarker!);
        }
        _currentLocationMarker = MapMarker(
          location.toHereMapCoordinate(),
          MapImage.withImageDataImageFormatWidthAndHeight(
              await AssetUtils.loadAssetImage(Assets.currentPoistionIcon),
              ImageFormat.svg,
              24,
              24),
        );
        controller.mapScene.addMapMarker(_currentLocationMarker!);
      },
    );
  }
}

extension ToHereCoordinate on MapLocation {
  GeoCoordinates toHereMapCoordinate() {
    return GeoCoordinates(lat, long);
  }
}

// extension ToGeo on LatLng {
//   MapLatLng toMapLatLng() {
//     return MapLatLng(lat: latitude, lng: longitude);
//   }
// }
