// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:here_panda_map/extensions/map_extensions.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:panda_map/core/models/map_current_location_style.dart';

class CustomLocationIndicator {
  CustomLocationIndicator({
    MapCurrentLocationStyle style = MapCurrentLocationStyle.normal,
  }) : _style = style;
  MapCurrentLocationStyle _style;
  MapCurrentLocationStyle get style => _style;

  late final LocationIndicator _defaultLocationIndicator = LocationIndicator();
  late HereMapController _mapController;
  ui.Image? _driverImage;
  MapMarker? _locationMarker;

  Future<void> changeStyle(MapCurrentLocationStyle newStyle) async {
    if (newStyle.isDifferentStyleGroup(style)) {
      disable();
      _style = newStyle;
      await enable(_mapController);
    } else {
      _style = newStyle;
      if (MapCurrentLocationStyle.hereStylesGroup.contains(newStyle)) {
        _defaultLocationIndicator.locationIndicatorStyle = newStyle.toHereStyle;
      }
    }
  }

  Future<void> enable(HereMapController controller) async {
    _mapController = controller;
    try {
      switch (style) {
        case MapCurrentLocationStyle.normal:
        case MapCurrentLocationStyle.navigation:
          _defaultLocationIndicator.enable(controller);
        case MapCurrentLocationStyle.tracking:
      }
    } catch (e) {
      log('enable CustomLocationIndicator error $e');
    }
  }

  void disable() {
    switch (style) {
      case MapCurrentLocationStyle.normal:
      case MapCurrentLocationStyle.navigation:
        _defaultLocationIndicator.disable();
      case MapCurrentLocationStyle.tracking:
    }
  }

  Future<void> updateLocation(Location location) async {
    switch (style) {
      case MapCurrentLocationStyle.normal:
      case MapCurrentLocationStyle.navigation:
        _defaultLocationIndicator.updateLocation(location);
      case MapCurrentLocationStyle.tracking:
        log("Bearing ${location.bearingInDegrees!}");
        _driverImage ??= await _getDriverImage();
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
    painter.paint(
      canvas,
      Size(
        _driverImage!.width.toDouble(),
        _driverImage!.height.toDouble(),
      ),
    );
    final picture = recorder.endRecording();
    final rotatedImage =
        await picture.toImage(_driverImage!.width, _driverImage!.height);
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
