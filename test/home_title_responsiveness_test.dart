import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesocham/features/champions/data/local/local_champion_catalog.dart';
import 'package:mesocham/features/champions/presentation/widgets/champion_type_emblem.dart';
import 'package:mesocham/features/home/data/player_preferences.dart';
import 'package:mesocham/features/home/presentation/pages/home_page.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets(
    'home title stays on one line and scales across landscape screens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final titleWidths = <double>[];
      final emblemWidths = <double>[];

      for (final screenSize in const [
        Size(1280, 720),
        Size(1024, 768),
        Size(800, 600),
        Size(720, 405),
        Size(640, 480),
        Size(480, 320),
        Size(320, 240),
      ]) {
        tester.view.physicalSize = screenSize;
        await tester.pumpWidget(
          MaterialApp(
            home: HomePage(
              catalog: LocalChampionCatalog(),
              playerPreferences: PlayerPreferences(),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        for (final word in const ['MESOZOIC', 'CHAMPIONS']) {
          final wordFinder = find.text(word);
          expect(wordFinder, findsNWidgets(2));
          for (final text in tester.widgetList<Text>(wordFinder)) {
            expect(text.maxLines, 1);
            expect(text.softWrap, isFalse);
          }

          final wordRect = tester.getRect(wordFinder.last);
          expect(wordRect.left, greaterThanOrEqualTo(0));
          expect(wordRect.right, lessThanOrEqualTo(screenSize.width));
          if (word == 'CHAMPIONS') titleWidths.add(wordRect.width);
        }

        final emblemRect = tester.getRect(find.byType(ChampionTypeEmblem));
        expect(emblemRect.left, greaterThanOrEqualTo(0));
        expect(emblemRect.right, lessThanOrEqualTo(screenSize.width));
        emblemWidths.add(emblemRect.width);
      }

      for (var index = 1; index < emblemWidths.length; index++) {
        expect(emblemWidths[index], lessThan(emblemWidths[index - 1]));
        expect(titleWidths[index], lessThan(titleWidths[index - 1]));
      }
    },
  );
}
