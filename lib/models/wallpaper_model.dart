class WallpaperModel {
  final int id;
  final String name;
  final List<String> layers;

  WallpaperModel({
    required this.id,
    required this.name,
    required this.layers,
  });

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: json["id"],
      name: json["name"],
      layers: List<String>.from(json["layers"]),
    );
  }
} 
