import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/panda_map.dart';
import 'package:panda_map/utils/constants.dart';
import 'package:panda_map/widgets/map/current_location_button.dart';

class HereMapNavigationOverlay extends StatelessWidget {
  HereMapNavigationOverlay({
    super.key,
  });

  final PandaRoutingController routingController = PandaMap.routingController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: routingController,
        builder: (context, child) {
          if (routingController.currentRoute == null) {
            return emptyWidget;
          }

          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoveDirection(routingController: routingController),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CurrentLocationButton(controller: PandaMap.controller),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
