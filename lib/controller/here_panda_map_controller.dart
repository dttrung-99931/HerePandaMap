import 'dart:async';
import 'dart:developer';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:panda_map/assets/assets.dart';
import 'package:panda_map/core/controllers/panda_map_controller.dart';
import 'package:panda_map/core/models/map_lat_lng.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/services/map_service.dart';
import 'package:panda_map/panda_map_options.dart' as panda_map;
import 'package:panda_map/utils/asset_utils.dart';

// Controler [GoogleMap]
class HerePandaMapController extends PandaMapController {
  HerePandaMapController({MapService? service})
      : _mapService = service ?? MapService();

  late final LocationIndicator _locationIndicator = LocationIndicator()
    ..locationIndicatorStyle = LocationIndicatorIndicatorStyle.pedestrian;

  // final Set<Marker> markers = <Marker>{};
  // final Set<Circle> circles = <Circle>{};
  Completer<HereMapController> _controllerCompleter = Completer();

  // MapType get mapType => MapType.values[currentMapTypeIndex];

  MapMarker? _currentLocationMarker;

  final int _currentMapTypeIndex = 1;
  final MapService _mapService;

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
  void dispose() {
    SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    super.dispose();
  }

  @override
  Future<void> focusCurrentLocation({bool animate = true}) async {
    MapLocation? location = await _mapService.getCurrentLocation();
    if (location != null) {
      focusMapTo(location);
      _locationIndicator.updateLocation(
        Location.withCoordinates(location.toHereMapCoordinate()),
      );
    } else {
      log('Google map: FInd location failed');
    }
  }

  @override
  Future<void> focusMapTo(MapLocation location, {bool animate = true}) async {
    return control((HereMapController controller) {
      MapCameraAnimation amim = MapCameraAnimationFactory.flyTo(
        GeoCoordinatesUpdate(location.lat, location.long),
        1,
        const Duration(milliseconds: 800),
      );
      controller.camera.startAnimation(amim);
    });
  }

  @override
  Future<void> init(panda_map.MapOptions options) async {
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

  Future<HereMapController> get controllerFuture => _controllerCompleter.future;

  int get currentMapTypeIndex => _currentMapTypeIndex;

  void onMapCreated(HereMapController controller) {
    // onMapCreated may be called many times by MapScreen due to back to home screen
    if (_controllerCompleter.isCompleted) {
      _controllerCompleter = Completer();
    }
    _controllerCompleter.complete(controller);
    // controller.
    controller.camera.lookAtPoint(hcmCityCoordimate.toHereMapCoordinate());
    controller.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError? error) {
      if (error != null) {
        print('Map scene not loaded. MapError: ${error.toString()}');
        return;
      }

      // const double distanceToEarthInMeters = 8000;
      // MapMeasure mapMeasureZoom =
      //     MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);
      // controller.camera.lookAtPointWithMeasure(
      //     GeoCoordinates(52.530932, 13.384915), mapMeasureZoom);
      _locationIndicator.enable(controller);
      focusCurrentLocation(animate: false);
    });
  }

  Future<void> control(Function(HereMapController controller) action) async {
    HereMapController controller = await controllerFuture;
    action(controller);
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
