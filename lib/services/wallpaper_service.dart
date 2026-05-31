import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/wallpaper_model.dart';

class WallpaperService {
  static Future<List<WallpaperModel>> loadWallpapers() async {
    final jsonString =
        await rootBundle.loadString("assets/wallpapers.json");

    final List data = jsonDecode(jsonString);

    return data
        .map((e) => WallpaperModel.fromJson(e))
        .toList();
  }
} 
