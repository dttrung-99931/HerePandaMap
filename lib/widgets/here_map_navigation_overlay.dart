import 'package:flutter/material.dart';
import 'package:here_panda_map/controller/here_routing_controller.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/core/models/map_address_location.dart';
import 'package:panda_map/panda_map.dart';
import 'package:panda_map/widgets/map/current_location_button.dart';
import 'package:panda_map/widgets/map/route_locations.dart';
import 'package:panda_map/widgets/map/zoom_buttons.dart';
import 'package:panda_map/widgets/map_action_button.dart';

class HereMapNavigationOverlay extends StatelessWidget {
  HereMapNavigationOverlay({
    super.key,
  });

  final HereRoutingController routingController =
      PandaMap.routingController as HereRoutingController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: routingController,
        builder: (context, child) {
          switch (routingController.status) {
            case HereRoutingStatus.previewRoute:
              return PreviewRouteOverlay(
                routeLocations: routingController.previewRoute.locations,
                routingController: routingController,
              );
            case HereRoutingStatus.navigating:
              return NoRoutingOverlay(routingController: routingController);
            case HereRoutingStatus.noRouting:
              return NoRoutingOverlay(routingController: routingController);
          }
        },
      ),
    );
  }
}

class PreviewRouteOverlay extends StatelessWidget {
  const PreviewRouteOverlay({
    super.key,
    required this.routeLocations,
    required this.routingController,
  });

  final List<MapAddressLocation> routeLocations; // start, ..., dest
  final HereRoutingController routingController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RouteLocations(routeLocations),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MapActionButton(
                  onPressed: () {
                    routingController.startNavigation(
                      routingController.previewRoute,
                    );
                  },
                  icon: Icons.navigation_outlined,
                  size: 32,
                ),
                const SizedBox(width: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ZoomButtons(controller: PandaMap.controller),
                    const SizedBox(height: 8),
                    CurrentLocationButton(controller: PandaMap.controller),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoRoutingOverlay extends StatelessWidget {
  const NoRoutingOverlay({
    super.key,
    required this.routingController,
  });

  final HereRoutingController routingController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoveDirection(routingController: routingController),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ZoomButtons(controller: PandaMap.controller),
                const SizedBox(height: 8),
                CurrentLocationButton(controller: PandaMap.controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoveDirection extends StatelessWidget {
  const MoveDirection({
    super.key,
    required this.routingController,
  });

  final PandaRoutingController routingController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: PandaMap.uiOptions.routeColor,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  spreadRadius: 1,
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.01),
                )
              ],
            ),
            child: const Icon(Icons.volume_up_outlined),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              routingController.currentMoveStep.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
