// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_sdk/mapview.dart';

class HereMapWidget extends StatelessWidget {
  const HereMapWidget({
    super.key,
    required this.controller,
  });

  final HerePandaMapController controller;

  @override
  Widget build(BuildContext context) {
    return HereMap(
      onMapCreated: controller.onMapCreated,
    );
  }
}
