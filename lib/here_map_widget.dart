// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_sdk/mapview.dart';

class HereMapWidget extends StatefulWidget {
  const HereMapWidget({
    super.key,
    required this.controller,
  });

  final HerePandaMapController controller;

  @override
  State<HereMapWidget> createState() => _HereMapWidgetState();
}

class _HereMapWidgetState extends State<HereMapWidget> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HereMap(
      onMapCreated: widget.controller.onMapCreated,
    );
  }
}
