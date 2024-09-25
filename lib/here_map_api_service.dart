import 'dart:async';

import 'package:here_panda_map/extensions/map_extensions.dart';
import 'package:here_panda_map/models/here_address_component_dto.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:panda_map/core/dtos/map_address_component_dto.dart';
import 'package:panda_map/core/dtos/map_location_dto.dart';
import 'package:panda_map/core/dtos/map_place_detail_dto.dart';
import 'package:panda_map/core/dtos/map_place_dto.dart';
import 'package:panda_map/core/dtos/map_search_result_dto.dart';
import 'package:panda_map/core/exceptions/search_exception.dart';
import 'package:panda_map/core/models/map_location.dart';
import 'package:panda_map/core/services/map_api_service.dart';

class HereMapAPIService implements MapAPIService {
  HereMapAPIService._();
  static HereMapAPIService? _instance;
  factory HereMapAPIService() {
    return _instance ??= HereMapAPIService._();
  }

  late final SearchEngine _searchEngine = SearchEngine();
  late final SearchOptions _searchOption = SearchOptions()
    ..maxItems = 30
    ..languageCode = LanguageCode.viVn;

  @override
  Future<MapSearchResultDto> searchLocations(String text) async {
    // TODO: impl searchLocations. It't different with findLocations that search for address more correty
    return findLocations(text);
  }

  @override
  Future<MapSearchResultDto> findLocations(String text) async {
    Completer<MapSearchResultDto> completer = Completer();
    _searchEngine.searchByAddress(
      AddressQuery(text),
      _searchOption,
      (SearchError? error, List<Place>? places) {
        if (error != null && ![SearchError.noResultsFound].contains(error)) {
          completer.completeError(SearchException(message: error.toString()));
          return;
        }
        MapSearchResultDto searchResult = MapSearchResultDto(
          places: (places ?? []).map(
            (place) {
              return MapPlaceDto(
                placeId: place.id,
                formattedAddress: place.address.addressText,
                displayName: MapPlaceNameDto(
                  text: place.title,
                  languageCode: LanguageCode.viVn.name,
                ),
                location: MapLocationDto(
                  latitude: place.geoCoordinates?.latitude ?? -1,
                  longitude: place.geoCoordinates?.longitude ?? -1,
                ),
                addressComponent: HereAddressComponentDto.fromPlace(place),
              );
            },
          ).toList(),
        );
        completer.complete(searchResult);
      },
    );
    return completer.future;
  }

  @override
  Future<MapPlaceDetailDto> getPlaceDetail(String placeId) async {
    throw 'Not implemented';
  }

  @override
  Future<MapAddressComponentDto?> getAddressByGeo(MapLocation location) {
    final options = SearchOptions()
      ..languageCode = LanguageCode.viVn
      ..maxItems = 1;
    final completer = Completer<MapAddressComponentDto?>();
    _searchEngine.searchByCoordinates(
      location.toHereMapCoordinate(),
      options,
      (SearchError? error, List<Place>? places) {
        if (error != null) {
          completer.completeError(error);
          return;
        }
        if (places == null || places.isEmpty) {
          completer.complete(null);
          return;
        }
        final Place place = places.first;
        final address = HereAddressComponentDto.fromPlace(place);
        completer.complete(address);
      },
    );
    return completer.future;
  }
}
