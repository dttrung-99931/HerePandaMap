import 'package:flutter/src/widgets/framework.dart';
import 'package:here_panda_map/controller/here_panda_map_controller.dart';
import 'package:here_panda_map/controller/here_routing_controller.dart';
import 'package:here_panda_map/here_map_api_service.dart';
import 'package:here_panda_map/here_map_options.dart';
import 'package:here_panda_map/here_map_widget.dart';
import 'package:panda_map/core/controllers/pada_routing_controller.dart';
import 'package:panda_map/core/controllers/panda_map_controller.dart';
import 'package:panda_map/core/services/map_api_service.dart';
import 'package:panda_map/panda_map_plugin.dart';

class HerePandaMapPluggin extends PandaMapPlugin {
  HerePandaMapPluggin({required HerePandaMapOptions options})
      : super(options: options);

  @override
  Widget buildMap(
      BuildContext context, covariant HerePandaMapController controller) {
    return HereMapWidget(controller: controller);
  }

  @override
  PandaMapController createController() {
    return HerePandaMapController();
  }

  @override
  MapAPIService createService() {
    return HereMapAPIService();
  }

  @override
  PandaRoutingController createRoutingController(
      covariant HerePandaMapController mapController) {
    return HereRoutingController(mapController: mapController);
  }
}
