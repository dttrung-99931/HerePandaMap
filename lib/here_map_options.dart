import 'package:panda_map/panda_map_options.dart';

class HerePandaMapOptions extends MapOptions {
  HerePandaMapOptions({
    required super.mapAPIKey,
    required this.mapAPIKeyId,
  });
  final String mapAPIKeyId;
}
