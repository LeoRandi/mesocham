import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/mesozoic_champions_app.dart';
import 'features/champions/data/local/local_champion_catalog.dart';
import 'features/home/data/player_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MesozoicChampionsApp(
      catalog: LocalChampionCatalog(),
      playerPreferences: PlayerPreferences(),
    ),
  );
}
