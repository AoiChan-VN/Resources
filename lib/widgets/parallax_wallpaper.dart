import 'package:flutter/material.dart';

class ParallaxWallpaper extends StatelessWidget {
  final List<String> layers;
  final double offsetX;
  final double offsetY;

  const ParallaxWallpaper({
    super.key,
    required this.layers,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        layers.length,
        (index) {
          double depth =
              (index + 1) * 10;

          return Positioned.fill(
            child: Transform.translate(
              offset: Offset(
                offsetX * depth,
                offsetY * depth,
              ),
              child: Image.asset(
                layers[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
} 
