// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';

enum CustomLocationIndicatorStyle {
  pedestrian,
  navigation,
  motorbikeTracking;

  static List<CustomLocationIndicatorStyle> hereStylesGroup = [
    pedestrian,
    navigation,
  ];
  static List<CustomLocationIndicatorStyle> _customStypesGroup = [
    motorbikeTracking
  ];
  static List<List<CustomLocationIndicatorStyle>> _styleGroups = [
    hereStylesGroup,
    _customStypesGroup,
  ];
  bool isDifferentStyleGroup(CustomLocationIndicatorStyle style) {
    return _styleGroups.indexWhere((styles) => styles.contains(this)) !=
        _styleGroups.indexWhere((styles) => styles.contains(style));
  }

  LocationIndicatorIndicatorStyle get toHereStyle {
    switch (this) {
      case CustomLocationIndicatorStyle.pedestrian:
        return LocationIndicatorIndicatorStyle.pedestrian;
      case CustomLocationIndicatorStyle.navigation:
        return LocationIndicatorIndicatorStyle.navigation;
      case CustomLocationIndicatorStyle.motorbikeTracking:
        throw 'Cannot convert $this to CustomLocationIndicatorStyle';
    }
  }
}

class CustomLocationIndicator {
  CustomLocationIndicator({
    CustomLocationIndicatorStyle style =
        CustomLocationIndicatorStyle.pedestrian,
  }) : _style = style;
  CustomLocationIndicatorStyle _style;
  CustomLocationIndicatorStyle get style => _style;

  late final LocationIndicator _defaultLocationIndicator = LocationIndicator();
  late HereMapController _mapController;
  late ui.Image _driverImage;
  final Completer<bool> _enaledCompleter = Completer();
  MapMarker? _locationMarker;

  Future<void> changeStyle(CustomLocationIndicatorStyle newStyle) async {
    if (newStyle.isDifferentStyleGroup(style)) {
      disable();
      _style = newStyle;
      await enable(_mapController);
    } else {
      _style = newStyle;
      if (CustomLocationIndicatorStyle.hereStylesGroup.contains(newStyle)) {
        _defaultLocationIndicator.locationIndicatorStyle = newStyle.toHereStyle;
      }
    }
  }

  Future<void> enable(HereMapController controller) async {
    try {
      switch (style) {
        case CustomLocationIndicatorStyle.pedestrian:
        case CustomLocationIndicatorStyle.navigation:
          _defaultLocationIndicator.enable(controller);
        case CustomLocationIndicatorStyle.motorbikeTracking:
          _mapController = controller;
          _driverImage = await _getDriverImage();
      }
      _enaledCompleter.complete(true);
    } catch (e) {
      log('enable CustomLocationIndicator error $e');
      _enaledCompleter.complete(false);
    }
  }

  void disable() {
    switch (style) {
      case CustomLocationIndicatorStyle.pedestrian:
      case CustomLocationIndicatorStyle.navigation:
        _defaultLocationIndicator.disable();
      case CustomLocationIndicatorStyle.motorbikeTracking:
    }
  }

  Future<void> updateLocation(Location location) async {
    if (!(await _enaledCompleter.future)) {
      return;
    }
    switch (style) {
      case CustomLocationIndicatorStyle.pedestrian:
      case CustomLocationIndicatorStyle.navigation:
        _defaultLocationIndicator.updateLocation(location);
      case CustomLocationIndicatorStyle.motorbikeTracking:
        log("Bearing ${location.bearingInDegrees!}");
        Uint8List rotatedDriverImg =
            await _getRotatedDriverImage(location.bearingInDegrees!);
        if (_locationMarker != null) {
          _mapController.mapScene.removeMapMarker(_locationMarker!);
        }
        _mapController.mapScene.addMapMarker(
          _locationMarker = MapMarker(
            location.coordinates,
            MapImage.withImageDataImageFormatWidthAndHeight(
              rotatedDriverImg,
              ImageFormat.png,
              156,
              156,
            ),
          ),
        );
    }
  }

  Future<ui.Image> _getDriverImage() async {
    final data =
        await rootBundle.load('packages/here_panda_map/assets/ic_driver.png');
    final image = await decodeImageFromList(data.buffer.asUint8List());
    return image;
  }

  Future<Uint8List> _getRotatedDriverImage(double bearingInDegrees) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _CanvasPainter(
      image: _driverImage,
      // _driverImage's bearing is 180deg
      // => calcuate rorated angle degress
      bearingInDegree: bearingInDegrees - 180,
    );
    // log("camera bearing ${_mapController.camera.state.}");
    painter.paint(canvas,
        Size(_driverImage.width.toDouble(), _driverImage.height.toDouble()));
    final picture = recorder.endRecording();
    final rotatedImage =
        await picture.toImage(_driverImage.width, _driverImage.height);
    final byteData =
        await rotatedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _CanvasPainter extends CustomPainter {
  final ui.Image? image;
  final double bearingInDegree;

  _CanvasPainter({
    this.image,
    required this.bearingInDegree,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(bearingInDegree * math.pi / 180);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawImage(image!, Offset.zero, Paint());
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
