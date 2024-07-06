import 'package:here_sdk/search.dart';
import 'package:panda_map/core/dtos/map_address_component_dto.dart';

class HereAddressComponentDto extends MapAddressComponentDto {
  HereAddressComponentDto({
    required super.provinceOrCity,
    required super.district,
    required super.communeOrWard,
    required super.streetAndHouseNum,
  });

  factory HereAddressComponentDto.fromPlace(Place place) {
    return HereAddressComponentDto(
      provinceOrCity: place.address.city,
      district: place.address.district,
      communeOrWard: place.address.city, // FIXME
      streetAndHouseNum:
          '${place.address.street} ${place.address.houseNumOrName}}',
    );
  }
}
