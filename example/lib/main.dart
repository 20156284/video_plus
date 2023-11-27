import 'package:flutter/material.dart';
import 'package:video_plus/video_plus.dart';

import 'animation_player/animation_player.dart';
import 'custom_orientation_player/custom_orientation_player.dart';
import 'default_player/default_player.dart';
import 'feed_player/feed_player.dart';
import 'landscape_player/landscape_player.dart';
import 'short_video_player/short_video_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VideoPlus.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Video Plus example',
      home: Scaffold(
        body: SafeArea(child: Examples()),
      ),
    );
  }
}

class Examples extends StatefulWidget {
  const Examples({super.key});

  @override
  State<Examples> createState() => _ExamplesState();
}

class _ExamplesState extends State<Examples> {
  final List<Map<String, dynamic>> samples = [
    {'name': 'Default player', 'widget': const DefaultPlayer()},
    {
      'name': 'Animation player',
      'widget': const Expanded(child: AnimationPlayer())
    },
    {'name': 'Feed player', 'widget': const Expanded(child: FeedPlayer())},
    {
      'name': 'Custom orientation player',
      'widget': const CustomOrientationPlayer()
    },
    {'name': 'Landscape player', 'widget': const LandscapePlayer()},
    {
      'name': 'Short Video Player',
      'widget': const Expanded(child: ShortVideoHomePage())
    },
  ];

  int selectedIndex = 0;

  void changeSample(int index) {
    if (samples[index]['widget'] is LandscapePlayer) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const LandscapePlayer(),
      ));
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
          child: samples[selectedIndex]['widget'],
        ),
        Container(
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: ListView(
              scrollDirection: Axis.horizontal,
              children: samples.asMap().keys.map(
                (index) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        changeSample(index);
                      },
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            samples.asMap()[index]?['name'],
                            style: TextStyle(
                              color: index == selectedIndex
                                  ? const Color.fromRGBO(100, 109, 236, 1)
                                  : const Color.fromRGBO(173, 176, 183, 1),
                              fontWeight: index == selectedIndex
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList()),
        ),
      ],
    );
  }
}
