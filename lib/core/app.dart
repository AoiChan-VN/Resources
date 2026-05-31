import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

class Wallpaper4DApp extends StatelessWidget {
  const Wallpaper4DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallpaper 4D',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
} 
