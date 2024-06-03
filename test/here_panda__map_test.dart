// import 'package:flutter_test/flutter_test.dart';
// import 'package:here_panda_map/here_panda_map.dart';
// import 'package:here_panda_map/here_panda_map_platform_interface.dart';
// import 'package:here_panda_map/here_panda_map_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockHerePandaMapPlatform
//     with MockPlatformInterfaceMixin
//     implements HerePandaMapPlatform {
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final HerePandaMapPlatform initialPlatform = HerePandaMapPlatform.instance;

//   test('$MethodChannelHerePandaMap is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelHerePandaMap>());
//   });

//   test('getPlatformVersion', () async {
//     HerePandaMap herePandaMapPlugin = HerePandaMap();
//     MockHerePandaMapPlatform fakePlatform = MockHerePandaMapPlatform();
//     HerePandaMapPlatform.instance = fakePlatform;

//     expect(await herePandaMapPlugin.getPlatformVersion(), '42');
//   });
// }
