import 'package:here_sdk/core.dart';
import 'package:here_sdk/routing.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/models/map_move_action.dart';
import 'package:panda_map/core/models/map_move_step.dart';
import 'package:panda_map/core/models/map_polyline.dart';

extension MapLocationExt on MapLocation {
  GeoCoordinates toHereMapCoordinate() {
    return GeoCoordinates(lat, long);
  }
}

extension GeoCoordinatesExt on GeoCoordinates {
  MapLocation toMapLocation() {
    return MapLocation(lat: latitude, long: longitude);
  }
}

extension MapPolylineExt on MapPolyline {
  GeoPolyline toHereMapGeoPolyline() {
    return GeoPolyline(vertices.map((e) => e.toHereMapCoordinate()).toList());
  }
}

extension ManeuverExt on Maneuver {
  MapMoveStep toMoveStep() {
    return MapMoveStep(
      action: action.toMoveAction(),
      location: coordinates.toMapLocation(),
      text: text,
    );
  }
}

extension MapMoveActionExt on ManeuverAction {
  MapMoveAction toMoveAction() {
    switch (this) {
      case ManeuverAction.depart:
        return MapMoveAction.depart;
      case ManeuverAction.arrive:
        return MapMoveAction.arrive;
      case ManeuverAction.leftTurn:
        return MapMoveAction.leftTurn;
      case ManeuverAction.slightLeftTurn:
        return MapMoveAction.slightLeftTurn;
      case ManeuverAction.continueOn:
        return MapMoveAction.continueOn;
      case ManeuverAction.slightRightTurn:
        return MapMoveAction.slightRightTurn;
      case ManeuverAction.rightTurn:
        return MapMoveAction.rightTurn;
      // TODO: implm
      case ManeuverAction.sharpRightTurn:
      case ManeuverAction.leftUTurn:
      case ManeuverAction.sharpLeftTurn:
      case ManeuverAction.rightUTurn:
      case ManeuverAction.leftExit:
      case ManeuverAction.rightExit:
      case ManeuverAction.leftRamp:
      case ManeuverAction.rightRamp:
      case ManeuverAction.leftFork:
      case ManeuverAction.middleFork:
      case ManeuverAction.rightFork:
      case ManeuverAction.enterHighwayFromLeft:
      case ManeuverAction.enterHighwayFromRight:
      case ManeuverAction.leftRoundaboutEnter:
      case ManeuverAction.rightRoundaboutEnter:
      case ManeuverAction.leftRoundaboutPass:
      case ManeuverAction.rightRoundaboutPass:
      case ManeuverAction.leftRoundaboutExit1:
      case ManeuverAction.leftRoundaboutExit2:
      case ManeuverAction.leftRoundaboutExit3:
      case ManeuverAction.leftRoundaboutExit4:
      case ManeuverAction.leftRoundaboutExit5:
      case ManeuverAction.leftRoundaboutExit6:
      case ManeuverAction.leftRoundaboutExit7:
      case ManeuverAction.leftRoundaboutExit8:
      case ManeuverAction.leftRoundaboutExit9:
      case ManeuverAction.leftRoundaboutExit10:
      case ManeuverAction.leftRoundaboutExit11:
      case ManeuverAction.leftRoundaboutExit12:
      case ManeuverAction.rightRoundaboutExit1:
      case ManeuverAction.rightRoundaboutExit2:
      case ManeuverAction.rightRoundaboutExit3:
      case ManeuverAction.rightRoundaboutExit4:
      case ManeuverAction.rightRoundaboutExit5:
      case ManeuverAction.rightRoundaboutExit6:
      case ManeuverAction.rightRoundaboutExit7:
      case ManeuverAction.rightRoundaboutExit8:
      case ManeuverAction.rightRoundaboutExit9:
      case ManeuverAction.rightRoundaboutExit10:
      case ManeuverAction.rightRoundaboutExit11:
      case ManeuverAction.rightRoundaboutExit12:
        // For all below action, seem this as  continueOn
        // TODO: Impl more corresponding MapMoveAction action
        return MapMoveAction.continueOn;
    }
  }
}
