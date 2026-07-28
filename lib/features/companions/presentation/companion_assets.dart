import '../domain/entities/companion.dart';

extension CompanionAsset on Companion {
  String get assetPath => switch (this) {
    Companion.dragonfly => 'assets/companions/libelula.jpg',
    Companion.ammonoidea => 'assets/companions/ammonoidea.jpg',
    Companion.weta => 'assets/companions/weta.jpg',
    Companion.horseshoeCrab => 'assets/companions/cangrejo_herradura.jpg',
    Companion.longisquama => 'assets/companions/longuisquama.jpg',
    Companion.didelphodon => 'assets/companions/didelphodon.jpg',
    Companion.simosuchus => 'assets/companions/simosuchus.jpg',
    Companion.iberomesornis => 'assets/companions/iberomesornis.jpg',
    Companion.beetle => 'assets/companions/escarabajo.jpg',
    Companion.henodus => 'assets/companions/henodus.jpg',
  };
}
