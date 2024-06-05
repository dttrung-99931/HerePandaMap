import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:here_panda_map/here_map_options.dart';
import 'package:here_panda_map/here_panda_map_pluggin.dart';
import 'package:panda_map/core/models/map_place.dart';
import 'package:panda_map/panda_map.dart';
import 'package:panda_map/panda_map_widget.dart';
import 'package:panda_map/widgets/search_bar/map_seach_button.dart';

Future<void> main() async {
  await PandaMap.initialize(
    plugin: HerePandaMapPluggin(
      options: HerePandaMapOptions(
        mapAPIKey:
            'yourMapAPIKey',
        mapAPIKeyId: 'yourMapAPIKeyId',
      ),
    ),
  );
  runApp(const PandaMapDemoApp());
}

class PandaMapDemoApp extends StatelessWidget {
  const PandaMapDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: const MapScreen(title: 'Flutter Demo Home Page'),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.title});

  final String title;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PandaMapWidget(),
          ),
          Positioned(
            top: 32,
            right: 16,
            child: MapSearchButton(
              onSelected: (MapPlace place) {
                log(place.location.lat.toString());
              },
            ),
          ),
        ],
      ),
    );
  }
}
