import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';
import '../services/wallpaper_service.dart';
import '../widgets/wallpaper_card.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<WallpaperModel> wallpapers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    wallpapers =
        await WallpaperService.loadWallpapers();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallpaper 4D"),
      ),
      body: ListView.builder(
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          final item = wallpapers[index];

          return WallpaperCard(
            title: item.name,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PreviewScreen(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
