// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_sdk/mapview.dart';
import 'package:panda_map/panda_map.dart';
import 'package:panda_map/widgets/loading_widget.dart';

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
    PandaMap.routingController.stopNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingListener(
      isLoadingNotifier: widget.controller.isLoading,
      child: HereMap(
        onMapCreated: widget.controller.onMapCreated,
        mode: NativeViewMode.hybridComposition,
      ),
    );
  }
}
