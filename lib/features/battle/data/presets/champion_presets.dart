import '../../domain/entities/battle_gesture.dart';
import '../../domain/entities/champion.dart';
import '../../domain/entities/champion_preset.dart';

abstract final class ChampionPresets {
  static const List<ChampionPreset> all = [
    // Jaw
    ChampionPreset(
      id: 'ornithosuchus',
      name: 'Ornithosuchus',
      scientificName: 'Ornithosuchus Longidens',
      type: ChampionType.jaw,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 4 m\nPeso: 200-350 Kg',
      discovery: 'Lossiemouth, Escocia\n1894\nPor Edwin Tully Newton',
      curiosity:
          'Originalmente se creyó que era un ancestro de los dinosaurios carnosaurios, pero hoy en día se sabe que está más relacionado con los cocodrilos.',
    ),
    ChampionPreset(
      id: 'ctenosauriscus',
      name: 'Ctenosauriscus',
      scientificName: 'Ctenosauriscus Koeneni',
      type: ChampionType.jaw,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Longitud: 3 m\nAltura: 1,5 m\nPeso: 100 Kg',
      discovery:
          'Gotinga, Alemania\n1871\nDescrito por Friedrich von Huene en 1902',
      curiosity:
          'Un estudio de 1998 propuso que el animal era bípedo y que sus espinas neurales alargadas servían para absorber las fuerzas ejercidas al caminar sobre dos piernas. En 2011 esta teoría se descartó.',
    ),
    ChampionPreset(
      id: 'allosaurus',
      name: 'Allosaurus',
      scientificName: 'Allosaurus Fragilis',
      type: ChampionType.jaw,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 8,5-9,7 m\nPeso: 1-2,3 Toneladas',
      discovery: 'Granby, Colorado\n1877\nPor Othniel Charles Marsh',
      curiosity:
          'Esta especie se ganó el mote de "el león del jurásico". Cazaban animales mucho más grandes y sufrían lesiones constantes.',
    ),
    ChampionPreset(
      id: 'dilophosaurus',
      name: 'Dilophosaurus',
      scientificName: 'Dilophosaurus Wetherilli',
      type: ChampionType.jaw,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 7 m\nPeso: 400 Kg',
      discovery: 'Arizona, Estados Unidos\n1954-1970\nPor Samuel P. Welles',
      curiosity:
          'No era capaz de escupir veneno como sugiere la saga "Parque Jurásico", y era mucho más grande que los que se pueden ver en dichas películas.',
    ),
    ChampionPreset(
      id: 'ceratosaurus',
      name: 'Ceratosaurus',
      scientificName: 'Ceratosaurus Nasicornis',
      type: ChampionType.jaw,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 7 m\nPeso: 980 Kg',
      discovery:
          'Formación Morrison, Estados Unidos\n1884\nPor Othniel Charles Marsh',
      curiosity:
          'Es uno de los dinosaurios más humillados en películas y series, ya que suele acabar ahuyentado o asesinado por otros depredadores más populares.',
    ),
    ChampionPreset(
      id: 'tyrannosaurus-rex',
      name: 'Tyrannosaurus Rex',
      scientificName: 'Tyrannosaurus Rex',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 12-13 m\nAltura: 4 m\nPeso: 6-9 Toneladas',
      discovery: 'Colorado, Estados Unidos\n1874\nPor Arthur Lakes',
      curiosity:
          'Un estudio sugirió que este animal era exclusivamente carroñero, debido a sus desarrollados sentidos del olfato y de la vista. Si bien es probable que a veces robaran las presas de otros cazadores, esta afirmación no duró mucho tiempo.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(
          name: 'Mordisco mortal',
          effectDescription: 'Daño + Hueso roto',
          isCritical: true,
        ),
        BattleGesture.paper: ChampionMovePreset(name: 'Emboscada'),
        BattleGesture.scissors: ChampionMovePreset(name: 'Rugido de caza'),
      },
    ),
    ChampionPreset(
      id: 'giganotosaurus',
      name: 'Giganotosaurus',
      scientificName: 'Giganotosaurus Carolinii',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 12-13 m\nPeso: 4-14 Toneladas',
      discovery: 'Patagonia argentina\n1993\nPor Rubén Carolini',
      curiosity:
          'Su inmenso tamaño ha abierto debates en la comunidad científica sobre el tamaño que pueden alcanzar los dinosaurios terópodos. Posiblemente fuera el depredador más grande de su época.',
    ),
    ChampionPreset(
      id: 'carnotaurus',
      name: 'Carnotaurus',
      scientificName: 'Carnotaurus Sastrei',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 7,5-8 m\nPeso: 1,3-2,1 Toneladas',
      discovery: 'Patagonia argentina\n1985\nPor José Fernando Bonaparte',
      curiosity:
          'Este animal poseía un cráneo pequeño, acompañado de un par de cuernos que le dieron el nombre de "toro carnívoro". Era muy ágil para su enorme tamaño.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Mandíbula letal'),
        BattleGesture.paper: ChampionMovePreset(
          name: 'Persecución',
          effectDescription:
              'Daño, + Daño si el rival ha cambiado de campeón este turno',
          isCritical: true,
        ),
        BattleGesture.scissors: ChampionMovePreset(name: 'Rugido de caza'),
      },
    ),
    ChampionPreset(
      id: 'albertosaurus',
      name: 'Albertosaurus',
      scientificName: 'Albertosaurus Sarcophagus',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 9 m\nPeso: 1,3-2,5 Toneladas',
      discovery: 'Alberta, Canadá\n1884\nPor Joseph Burr Tyrrell',
      curiosity:
          'Se han descubierto fósiles de más de 30 individuos, así que se tiene más conocimiento de este animal que de otros tiranosáuridos. El hallazgo de 26 individuos juntos evidencia comportamiento en grupos.',
    ),
    ChampionPreset(
      id: 'majungasaurus',
      name: 'Majungasaurus',
      scientificName: 'Majungasaurus Crenatissimus',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 6-8 m\nPeso: 1,1 Toneladas',
      discovery:
          'Río Betsiboka, Madagascar\n1896\nPor Charles Jean Julien Depéret',
      curiosity:
          'Es el único dinosaurio del que existe evidencia directa de canibalismo. Fue el carvívoro más grande de Madagascar.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(
          name: 'Canibalismo',
          effectDescription: 'Daño + pequeña sanación',
          isCritical: true,
        ),
        BattleGesture.paper: ChampionMovePreset(name: 'Emboscada'),
        BattleGesture.scissors: ChampionMovePreset(name: 'Rugido de caza'),
      },
    ),
    ChampionPreset(
      id: 'carcharadontosaurus',
      name: 'Carcharadontosaurus',
      scientificName: 'Carcharadontosaurus Saharicus',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 12 m\nPeso: 6-15 Toneladas',
      discovery:
          'Argelia\n1924\nPor Charles Jean Julien Depéret y Justin Savornin',
      curiosity:
          'Existen fósiles que muestran marcas de mordida del Carcharodontosaurus en las vértebras de un Spinosaurus, lo que sugiere que pudo existir una relación depredador/presa entre ambos.',
    ),
    ChampionPreset(
      id: 'nanotyrannus',
      name: 'Nanotyrannus',
      scientificName: 'Nanotyrannus Lancencis',
      type: ChampionType.jaw,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5 m\nPeso: 900 Kg',
      discovery: 'Jordan, Montana\n1942\nPor Charles Whitney Gilmore',
      curiosity:
          'Durante años se debatió si esta especie existió o si se trataba de un T. Rex juvenil. Tras un estudio en 2025 del famoso fósil "Dinosaurios en duelo", que conservaba los esqueletos de un Triceratops y un pequeño tiranosáurido, se concluyó que era una especie propia.',
    ),
    ChampionPreset(
      id: 'saurophaganax',
      name: 'Saurophaganax',
      scientificName: 'Saurophaganax Maximus',
      type: ChampionType.jaw,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 13 m\nPeso: 3-4,5 Toneladas',
      discovery:
          'Oklahoma, Estados Unidos\n1931-1932\nPor John Willis Stovall\nDescrito en 1941',
      curiosity:
          'Hasta principios de 2025, se le consideraba como una especie propia. Sin embargo, sus restos resultaron ser una quimera con restos de Allosaurio y de saurópodo. El nombre actual del esqueleto válido es Allosaurus anax.',
    ),

    // Nest
    ChampionPreset(
      id: 'placeria',
      name: 'Placeria',
      scientificName: 'Placeria Hesternus',
      type: ChampionType.nest,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 3,5 m\nPeso: 900-1000 Kg',
      discovery: 'Arizona, Estados Unidos\n1904\nPor Frederic Lucas',
      curiosity:
          'Este reptil, antepasado de los mamíferos fue una de las últimas especies del triásico en desaparecer frente al futuro reinado de los dinosaurios.',
    ),
    ChampionPreset(
      id: 'shirngasaurus',
      name: 'Shirngasaurus',
      scientificName: 'Shirngasaurus Indicus',
      type: ChampionType.nest,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 3 m\nPeso: 300-400 Kg',
      discovery: 'Madhya Pradesh, India\n2017\nPor Sengupta y colaboradores',
      curiosity:
          'Era un herbívoro cuadrúpedo con una apariencia maciza. Su cráneo era pequeño y rectangular, con dos cuernos cortos y cónicos que exhibía al igual que los dinosaurios ceratópsidos.',
    ),
    ChampionPreset(
      id: 'iguanodon',
      name: 'Iguanodon',
      scientificName: 'Iguanodon Bernissartensis',
      type: ChampionType.nest,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 10-13 m\nPeso: 3 Toneladas',
      discovery: 'Bernissart, Bélgica\n1881\nPor George Albert Boulenger',
      curiosity:
          'En la película "Dinosaurio" de Disney (2000) el protagonista es un Iguanodon llamado Aladar. Su diseño presenta algunas inconsistencias, como tener labios en vez de pico.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Nueva vida'),
        BattleGesture.paper: ChampionMovePreset(name: 'Embestida'),
        BattleGesture.scissors: ChampionMovePreset(
          name: 'Pulgar afilado',
          effectDescription: 'Daño + Ímpetu de alfa',
          isCritical: true,
        ),
      },
    ),
    ChampionPreset(
      id: 'dryosaurus',
      name: 'Dryosaurus',
      scientificName: 'Dryosaurus Altus',
      type: ChampionType.nest,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 3 m\nPeso: 100 Kg',
      discovery: 'Wyoming, Estados Unidos\n1878\nPor Othniel Charles Marsh',
      curiosity:
          'El tamaño de los adultos se desconoce, ya que aun no se han encontrado restos de especímenes adultos.',
    ),
    ChampionPreset(
      id: 'camptosaurus',
      name: 'Camptosaurus',
      scientificName: 'Camptosaurus Dispar',
      type: ChampionType.nest,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 5-8 m\nPeso: 500-2500 Kg',
      discovery: 'Wyoming, Estados Unidos\n1879\nPor William Harlow Reed',
      curiosity:
          'Originalmente se le llamó Camptonotus, pero se cambió en 1885 porque este nombre ya se utilizaba para referirse a grillos de cuernos largos.',
    ),
    ChampionPreset(
      id: 'parasaurolophus',
      name: 'Parasaurolophus',
      scientificName: 'Parasaurolophus Walkeri',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 9-11 m\nPeso: 2,7-3,6 Toneladas',
      discovery: 'Alberta, Canadá\n1922\nPor William Parks',
      curiosity:
          'Se cree que su cresta craneal servía como método de comunicación entre los de su especie y para regular la temperatura corporal.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Nueva vida'),
        BattleGesture.paper: ChampionMovePreset(
          name: 'Ataque sonoro',
          effectDescription: 'Daño + Intimidación',
          isCritical: true,
        ),
        BattleGesture.scissors: ChampionMovePreset(name: 'Puesto de vigía'),
      },
    ),
    ChampionPreset(
      id: 'maiasaura',
      name: 'Maiasaura',
      scientificName: 'Maiasaura Peeblesorum',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 9 m\nPeso: 3-4 Toneladas',
      discovery:
          'Montana, Estados Unidos\n1979\nPor Laurie Trexler\nDescrito por Jack Horner y \nRobert Makela',
      curiosity:
          'Su nombre significa "lagarto buena madre" en griego. Se le llamó así debido a la cantidad de nidos encontrados junto a sus restos en lo que hoy se conoce como la Montaña de los Huevos (EEUU).',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(
          name: 'Instinto maternal',
          effectDescription: 'Daño + Sanación',
          isCritical: true,
        ),
        BattleGesture.paper: ChampionMovePreset(name: 'Embestida'),
        BattleGesture.scissors: ChampionMovePreset(name: 'Puesto de vigía'),
      },
    ),
    ChampionPreset(
      id: 'therizinosaurus',
      name: 'Therizinosaurus',
      scientificName: 'Therizinosaurus Cheloniformis',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Longitud: 10 m\nAltura: 5 m\nPeso: 5 Toneladas',
      discovery:
          'Desierto de Gobi, Mongolia\n1948\nDescrito por Evgeny Maleev en 1954',
      curiosity:
          'Este animal pertenece a la familia de los terópodos, compuesta principalmente por carnívoros. Sin embargo, el Therizinosaurus fue herbívoro y usaba sus garras para defenderse en vez de para cazar.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Nueva vida'),
        BattleGesture.paper: ChampionMovePreset(name: 'Embestida'),
        BattleGesture.scissors: ChampionMovePreset(
          name: 'Cuchillada',
          effectDescription: 'Mucho daño',
          isCritical: true,
        ),
      },
    ),
    ChampionPreset(
      id: 'gallimimus',
      name: 'Gallimimus',
      scientificName: 'Gallimimus Bullatus',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 6 m\nPeso: 200 Kg',
      discovery:
          'Desierto de Gobi, Mongolia\n1972\nPor  Rinchen Barsbold, Halszka Osmólska y Ewa Roniewicz',
      curiosity:
          'Era un dinosaurio adaptado para la carrera. Su cuello y patas largas, además de su pico sin dientes, recuerdan a la avestruz actual.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Nueva vida'),
        BattleGesture.paper: ChampionMovePreset(
          name: 'Carrera',
          isCritical: true,
        ),
        BattleGesture.scissors: ChampionMovePreset(name: 'Puesto de vigía'),
      },
    ),
    ChampionPreset(
      id: 'oviraptor',
      name: 'Oviraptor',
      scientificName: 'Oviraptor Philoceratops',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 1,5 m\nPeso: 25-36 Kg',
      discovery: 'Omnogov, Mongolia\n1924\nPor Henry Fairfield Osborn',
      curiosity:
          'Este dinosaurio fue conicido como "el ladrón de huevos" durante muchos años porque algunos restos se encontraron cerca de nidos. En la actualidad, se teoriza que se trataban de nidos propios y que este animal fue herbívoro. ',
    ),
    ChampionPreset(
      id: 'pachycephalosaurus',
      name: 'Pachycephalosaurus',
      scientificName: 'Pachycephalosaurus Wyomingensis',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 4,5-5 m\nPeso: 450 Kg',
      discovery:
          'Montana, Estados Unidos\n1859-1860\nPor Ferdinand Vandeveer Hayden\nNombrado por Charles Whitney Gilmore en 1931',
      curiosity:
          'Se cree que no chocaban sus cabezas una contra la otra al pelear, sino que golpearían los costados del oponente de lado, como las jirafas.',
    ),
    ChampionPreset(
      id: 'deinocheirus',
      name: 'Deinocheirus',
      scientificName: 'Deinocheirus Mirificus',
      type: ChampionType.nest,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 11 m\nAltura: 3,3-4,4 m\nPeso: 6,5 Toneladas',
      discovery:
          'Desierto de Gobi, Mongolia\n1965\nNombrado por Halszka Osmólska y Ewa Roniewics en 1970',
      curiosity:
          'Sus brazos estaban entre los más grandes de cualquier dinosaurio bípedo (2,4 metros de largo) y tenía grandes garras en sus manos de tres dedos. Se cree que era omnívoro.',
    ),
    ChampionPreset(
      id: 'iguanodon-m',
      name: 'Iguanodon M.',
      scientificName: 'Iguanodon de Gideon Mantell',
      type: ChampionType.nest,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 9-11 m\nPeso: 4,5 Toneladas',
      discovery: 'Sussex, Inglaterra\n1822\nPor Gideon Mantell',
      curiosity:
          'Debido a sus dientes, que se asemejan a los de una Iguana, las primeras interpretaciones del animal se basaron en este reptil. Al descubrirse un solo pulgar, se creía que se trataba de un cuerno que se encontraba sobre sus fosas nasales.',
    ),

    // Water
    ChampionPreset(
      id: 'nothosaurus',
      name: 'Nothosaurus',
      scientificName: 'Nothosaurus Mirabilis',
      type: ChampionType.water,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 5-7 m\nPeso: 80-150 Kg',
      discovery: 'Bayreuth, Alemania\n1834\nPor Georg Münster',
      curiosity:
          'Su nombre significa "falso lagarto", ya que no es como otros lagartos o dinosaurios, sino un reptil que se adaptó tempranamente al medio acuático.',
    ),
    ChampionPreset(
      id: 'placodus',
      name: 'Placodus',
      scientificName: 'Placodus Gigas',
      type: ChampionType.water,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 2 m\nPeso: 500 Kg',
      discovery: 'Cuenca germánica, Alemania\n1833\nPor Louis Agassiz',
      curiosity:
          'Placodus y sus parientes no estaban tan bien adaptados a la vida marina como otros reptiles posteriores. Su cola aplanada y sus cortas patas fueron sus principales medios de propulsión.',
    ),
    ChampionPreset(
      id: 'liopleurodon',
      name: 'Liopleurodon',
      scientificName: 'Lipleurodon Ferox',
      type: ChampionType.water,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 4,9-7 m\nPeso: 1-1,7 Toneladas',
      discovery: 'Boulogne-sur-Mer, Francia\n1873\nHenri-Émile Sauvage',
      curiosity:
          'Un estudio realizado con un robot nadador demostró que, aunque su forma de propulsión no es especialmente eficiente, provee una muy buena aceleración, algo deseable para un depredador de emboscada.',
    ),
    ChampionPreset(
      id: 'ichthyosaurus',
      name: 'Ichthyosaurus',
      scientificName: 'Ichthyosaurus Communis',
      type: ChampionType.water,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 1,5-3,3 m\nPeso: 91 Kg',
      discovery:
          'Condado de Dorset, Inglaterra\n1822\nPor Henry Thomas de la Beche y William Daniel Conybeare',
      curiosity:
          'Este reptil no solo comparte algunas características físicas con el delfín actual, también necesitaba salir a la superficie a respirar, además de dar a luz a sus crías.',
    ),
    ChampionPreset(
      id: 'plesiosaurus',
      name: 'Plesiosaurus',
      scientificName: 'Plesiosaurus Dolichodirus',
      type: ChampionType.water,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 3,5 m\nPeso: 500 Kg',
      discovery:
          'Condado de Dorset, Inglaterra\n1824\nPor Henry Thomas de la Beche y William Daniel Conybeare',
      curiosity:
          'La criatura del famoso mito del "monstruo del lago Ness" está basada en este animal. Se han encontrado numerosos restos fósiles con piedras en sus estómagos, dando a entender que las tragaban habitualmente, aunque el fin de tal comportamiento sigue debatiéndose.',
    ),
    ChampionPreset(
      id: 'mosasaurus',
      name: 'Mosasaurus',
      scientificName: 'Mosasaurus Hoffmannii',
      type: ChampionType.water,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 18 m\nPeso: 7-15 Toneladas',
      discovery:
          'Maastricht, Países Bajos\n1764\nRecolectados por Jean Baptiste Drouin en 1766',
      curiosity:
          'Al igual que el tiburón blanco, este animal cazaba impusándose hacia arriba y embistiendo a sus presas, siendo capaz de alcanzar los 50 Km/h en un segundo.',
    ),
    ChampionPreset(
      id: 'deinosuchus',
      name: 'Deinosuchus',
      scientificName: 'Deinosuchus Hatcheri',
      type: ChampionType.water,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 8-15 m\nPeso: 9 Toneladas',
      discovery:
          'Carolina del Norte, Estados Unidos\n1858\nPor Ebenezer Emmons\nDescrito por William Jacob Holland en 1909',
      curiosity:
          'Mucho más grande que los cocodrilos actuales, pero sin ser capaces de realizar el giro de la muerte. Este animal nos enseña lo eficaces que los crocodilianos han sido desde siempre.',
    ),
    ChampionPreset(
      id: 'koolasuchus',
      name: 'Koolasuchus',
      scientificName: 'Koolasuchus Cleelandi',
      type: ChampionType.water,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 4-5 m\nPeso: 1 Tonelada',
      discovery: 'Victoria, Australia\n1989\nPor Lesley Kool y Mike Cleeland',
      curiosity:
          'Su nombre significa "cocodrilo de Kool" en griego, haciendo un juego de palabras con el paleontólogo que lo descubrió y el clima frió en el que vivía. A pesar de su nombre, se trataba de un anfibio.',
    ),
    ChampionPreset(
      id: 'baryonyx',
      name: 'Baryonyx',
      scientificName: 'Baryonyx Walkeri',
      type: ChampionType.water,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 7,5-10 m\nPeso: 1,2-1,7 Toneladas',
      discovery:
          'Surrey, Inglaterra\n1983\nPor William J. Walker\nNombrado por Alan J. Charig y Angela C. Milner en 1987',
      curiosity:
          'Sus garras delanteras servían como anzuelo para pescar peces y que estos no escaran. El primer ejemplar fue encontrado en Inglaterra, aunque también se encontraron en Portugal y en España.',
    ),
    ChampionPreset(
      id: 'suchomimus',
      name: 'Suchomimus',
      scientificName: 'Suchomimus Tenerensis',
      type: ChampionType.water,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 10-11 m\nPeso: 2,5-5,2 Toneladas',
      discovery:
          'Desierto del Teneré, Níger\n1998\nPor Paul Calistus Sereno y compañía',
      curiosity:
          'Físicamente fue bastante parecido al baryonyx y probablemente tenían el mismo estilo de vida, pero llegó a medir más o menos el doble.',
    ),
    ChampionPreset(
      id: 'spinosaurus',
      name: 'Spinosaurus',
      scientificName: 'Spinosaurus Aegyptiacus',
      type: ChampionType.water,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 15-16 m\nPeso: 4-4,7 Toneladas',
      discovery:
          'Djoua, Argelia\n1898\nPor Fernand Foureau\nDescrito por Ernst Stromer en 1915',
      curiosity:
          'A día de hoy, el diseño de este dinosaurio es de los más discutidos. Los primeros restos que se encontraron del animal en Alemania fueron bombardeados durante la segunda guerra mundial.',
    ),
    ChampionPreset(
      id: 'spinofaarus',
      name: 'Spinofaarus',
      scientificName: 'Spinofaarus',
      type: ChampionType.water,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 15-16 m\nPeso: 4-4,7 Toneladas',
      discovery: '2012\nPor John Conway, C.M. Kosemen y Darren Naish',
      curiosity:
          'La comunidad de paleontólogos diseñó este animal a modo de broma en referencia a los constantes cambios en el diseño del Spinosaurus.',
    ),

    // Crown
    ChampionPreset(
      id: 'yinlong',
      name: 'Yinlong',
      scientificName: 'Yinlong Downsi',
      type: ChampionType.crown,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 1,2 m\nPeso: 15 Kg',
      discovery:
          'Xinyiang, China\n2006\nPor Xu Xing, Catherine Foster, Jim Clark y Mo Jinyou',
      curiosity:
          'Yinlong era bípedo y el más antiguo y primitivo ceratopsio conocido. Su nombre significa "Dragón oculto" en mandarín.',
    ),
    ChampionPreset(
      id: 'chaoyangsaurus',
      name: 'Chaoyangsaurus',
      scientificName: 'Chaoyangsaurus Youngi',
      type: ChampionType.crown,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Longitud: 3 m\nAltura: 1 m\nPeso: 108 Kg',
      discovery:
          'Liaoning, China\n1992\nDescrito por Zhao, Cheng y Xu en 1999\n',
      curiosity:
          'Ha sido parte de numerosas discusiones antes de su publicación oficial y ha tenido varios nombres considerados como nombres desnudos. Finalmente, recibió un nombre oficial en 1999.',
    ),
    ChampionPreset(
      id: 'triceratops',
      name: 'Triceratops',
      scientificName: 'Triceratops Horridus',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 7,9-9 m\nPeso: 6-12 Toneladas',
      discovery:
          'Denver, Colorado\n1887\nPor George Cannon\nDescrito por Othniel Charles Marsh en 1888',
      curiosity:
          'Este es el animal con mejor protección frontal que ha existido nunca. Se ha representado en numerosas ocasiones viviendo en manadas, pero se debate que pudo ser un animal solitario, debido a su baja inteligencia.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Escudo corona'),
        BattleGesture.paper: ChampionMovePreset(name: 'Pico quebrador'),
        BattleGesture.scissors: ChampionMovePreset(
          name: 'Embestida de las 3 puntas',
          effectDescription:
              'Daño. Hace el mismo daño cuando gana que cuando empata.',
          isCritical: true,
        ),
      },
    ),
    ChampionPreset(
      id: 'protoceratops',
      name: 'Protoceratops',
      scientificName: 'Protoceratops Andrewsi',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 1,8 m\nPeso: 60 Kg',
      discovery: 'Gansu, China\n1923\nPor Walter Granger y W. K. Gregory',
      curiosity:
          'Uno de los fósiles más famosos del mundo es el que nos muestra una batalla a muerte entre este animal y un Velociraptor. El Protoceratops muerde la muñeca del depredador, rompiéndola; mientras que el raptor le clava una de sus garras en el cuello.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Escudo corona'),
        BattleGesture.paper: ChampionMovePreset(
          name: 'Rompe muñecas',
          effectDescription: 'Daño + Hueso roto',
          isCritical: true,
        ),
        BattleGesture.scissors: ChampionMovePreset(name: 'Carga'),
      },
    ),
    ChampionPreset(
      id: 'pachyrhinosaurus',
      name: 'Pachyrhinosaurus',
      scientificName: 'Pachyrhinosaurus Canadensis',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5-8 m\nPeso: 3,3-4 Toneladas',
      discovery:
          'Alberta, Canadá\n1945\nDescrito por Charles Mortram Sternberg en 1950',
      curiosity:
          'Su cráneo era enorme, pero no presentaba cuernos. Al parecer la forma y el tamaño de su gola servía para reconocer a otros de su especie.',
    ),
    ChampionPreset(
      id: 'styracosaurus',
      name: 'Styracosaurus',
      scientificName: 'Styracosaurus Albertensis',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5,5 m\nPeso: 2,7 Toneladas',
      discovery:
          'Alberta, Canadá\n1913\nPor Charles Mortram Sternberg\nNombrado por Lawrence Lambe',
      curiosity:
          'Se caracteriza por un escudo cefálico con púas largas que se extienden desde el cuello, dos cuernos yugales bajo sus ojos y otro sobre su hocico, que podía alcanzar los 60 cm de largo y 15 de ancho.',
    ),
    ChampionPreset(
      id: 'torosaurus',
      name: 'Torosaurus',
      scientificName: 'Torosaurus Latus',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 7,5-9 m\nPeso: 6-11 Toneladas',
      discovery:
          'Wyoming, Estados Unidos\n1891\nPor John Bell Hatcher\nNombrado por Othniel Charles Marsh',
      curiosity:
          'Poseía uno de los cráneos más grandes que se han encontrado nunca en un animal terrestre, y se cree que eran capaces de bombear sangre a sus crestas para intimidar.',
    ),
    ChampionPreset(
      id: 'diabloceratops',
      name: 'Diabloceratops',
      scientificName: 'Diabloceratops Eatoni',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5,5 m\nPeso: 1-2 Toneladas',
      discovery: 'Utah, Estados Unidos\n2002\nPor Donald Deblieux',
      curiosity:
          'Su nombre viene dado por la forma de sus cuernos en el cráneo y por sus dos enormes picos en el volante.',
    ),
    ChampionPreset(
      id: 'einiosaurus',
      name: 'Einiosaurus',
      scientificName: 'Einiosaurus Procurvicornis',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 4,5 m\nPeso: 1,3 Toneladas',
      discovery: 'Montana, Estados Unidos\n1985\nPor Jack Horner',
      curiosity:
          'Tenía un cuerno nasal curvado, dos pequeños cuernos sobre los ojos y una gola ósea que se extendía desde la parte trasera del cráneo. Estudios recientes indican que tales rasgos podían variar según el individuo, siendo difícil entender su biología.',
    ),
    ChampionPreset(
      id: 'regaliceratops',
      name: 'Regaliceratops',
      scientificName: 'Regaliceratops Peterhewsi',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5 m\nPeso: 1,5 Toneladas',
      discovery:
          'Alberta, Canadá\n2005\nPor Peter Hews\nDescrito por Caleb Marshall Brown y Donald Henderson en 2015',
      curiosity:
          'Fue nombrado por su gola con placas, la cual se pensó que lucía parecida a una corona. En 2005, el geólogo Peter Hews descubrió un cráneo al que se le dio el apodo de "Hellboy" por sus cuernos y la dificultad de remover el fósil de la matriz rocosa.',
    ),
    ChampionPreset(
      id: 'nasutoceratops',
      name: 'Nasutoceratops',
      scientificName: 'Nasutoceratops Titusi',
      type: ChampionType.crown,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 4,5 m\nPeso: 1,5 Toneladas',
      discovery:
          'Utah, Estados Unidos\n2000\nPor el Proyecto Cuenca Kaiparowits\nNombrado por Eric Karl Lund, Scott D. Sampson y Mark A. Loewen en 2011. Publicado oficialmente en 2013',
      curiosity:
          'Su nombre científico viene del término nasutus en latín, que significa "de nariz grande", y ceratops, "cara con cuernos" en griego. Los elementos neumáticos en sus huesos nasales es un rasgo único y se desconoce en cualquier otro ceratópsido.',
    ),
    ChampionPreset(
      id: 'monoclonius',
      name: 'Monoclonius',
      scientificName: 'Monoclonius Crassus',
      type: ChampionType.crown,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 6 m\nPeso:1-3 Toneladas',
      discovery: 'Montana, Estados Unidos\n1876\nEdward Drinker Cope',
      curiosity:
          'Algunos paleontólogos piensan que en realidad los fósiles identificados como Monoclonius fueron posiblemente Centrosaurus de diferentes edades o sexo, por lo que la existencia del género no está clara.',
    ),

    // Titan
    ChampionPreset(
      id: 'plateosaurus',
      name: 'Plateosaurus',
      scientificName: 'Plateosaurus Trossingensis',
      type: ChampionType.titan,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 4-10 m\nPeso: 600-4000 Kg',
      discovery:
          'Trossingen, Alemania\n1834\nPor Johann Friedrich Engelhardt\nDescrito por Eberhard Frass en 1913',
      curiosity:
          'Se trata de uno de los dinosaurios mejor conocidos por la ciencia. Cerca de 100 esqueletos han sido encontrados, algunos de los cuales están casi completos.',
    ),
    ChampionPreset(
      id: 'tanystropheus',
      name: 'Tanystropheus',
      scientificName: 'Tanystropheus Conspicuus',
      type: ChampionType.titan,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Longitud: 6 m\nAltura: 1,8 m\nPeso: 140 Kg',
      discovery: 'Alpes suizos\n1852\nPor Christian Erich Hermann von Meyer',
      curiosity:
          'Su enorme cuello le permitió pescar peces desde la costa, sin necesidad de adaptarse a un estilo de vida acuático.',
    ),
    ChampionPreset(
      id: 'camelotia',
      name: 'Camelotia',
      scientificName: 'Camelotia Borealis',
      type: ChampionType.titan,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 11 m\nPeso: 10 Toneladas',
      discovery:
          'Somerset, Inglaterra\n1894\nPor W. Ashford-Sanford\nDescrito por Peter Malcolm Galton en 1985',
      curiosity:
          'Tenían un cuello corto que sostenía un cráneo bastante grande con ojos pequeños. Sus manos y pies tenían cinco dígitos cada uno, y en sus manos llevaban una gran garra.',
    ),
    ChampionPreset(
      id: 'diplodocus',
      name: 'Diplodocus',
      scientificName: 'Diplodocus Carnegii',
      type: ChampionType.titan,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 25 m\nAltura: 6,5 m\nPeso: 10-16 Toneladas',
      discovery:
          'Wyoming, Estados Unidos\n1899\nPor Jacob Wortman\nDescrito por John Bell Hatcher en 1901',
      curiosity:
          'El cuerpo de estos dinosaurios era tan grande que creaba un mini ecosistema formado por insectos y pequeños reptiles voladores.',
    ),
    ChampionPreset(
      id: 'brachiosaurus',
      name: 'Brachiosaurus',
      scientificName: 'Brachiosaurus Altithorax',
      type: ChampionType.titan,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 18-22 m\nAltura: 12-16 m\nPeso: 35-60 Toneladas',
      discovery: 'Colorado, Estados Unidos\n1903\nPor Elmer S. Riggs',
      curiosity:
          'Sus patas delanteras eran más largas que las traseras, característica a la que hace referencia su nombre; y su cola era más corta en proporción a su cuello que en otros saurópodos del Jurásico.',
    ),
    ChampionPreset(
      id: 'mamenchisaurus',
      name: 'Mamenchisaurus',
      scientificName: 'Mamenchisaurus Constructus',
      type: ChampionType.titan,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 20 m\nAltura: 11 m\nPeso: 27 Toneladas',
      discovery: 'Sichuan, China\n1952\nNombrado por C. C. Young en 1954',
      curiosity:
          'Su cráneo era extremadamente pequeño en relación con el cuerpo. Aun así, se cree que tenía muy buena vista.',
    ),
    ChampionPreset(
      id: 'turiasaurus',
      name: 'Turiasaurus',
      scientificName: 'Turiasaurus Riodevensis',
      type: ChampionType.titan,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 30-39 m\nPeso: 40-48 Toneladas',
      discovery:
          'Teruel, España\n2003\nDescrito por Royo-Torres, Cobos y Alcala en 2006',
      curiosity:
          'Sus dimensiones lo convierten en el mayor dinosaurio que habitó Europa y en uno de los mayores del mundo. Su nombre deriva de Turia, nombre de un río de Teruel, y del término griego sauros, que significa lagarto.',
    ),
    ChampionPreset(
      id: 'brontosaurus',
      name: 'Brontosaurus',
      scientificName: 'Brontosaurus Excelsus',
      type: ChampionType.titan,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 21-22 m\nPeso: 15-17 Toneladas',
      discovery: 'Wyoming, Estados Unidos\n1879\nPor Othniel Charles Marsh',
      curiosity:
          'Por mucho tiempo se consideró como un sinónimo más moderno de Apatosaurus. Sin embargo, un extenso estudio publicado en 2015 concluyó que Brontosaurus es un género válido de saurópodo y distinto de Apatosaurus.',
    ),
    ChampionPreset(
      id: 'amargasaurus',
      name: 'Amargasaurus',
      scientificName: 'Amargasaurus Cazaui',
      type: ChampionType.titan,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 9-10 m\nPeso: 2,6 Toneladas',
      discovery: 'Neuquén, Patagonia argentina\n1984\nPor Guillermo Rougier',
      curiosity:
          'Era pequeño para un saurópodo. Su característica principal eran dos filas paralelas de espinas en su cuello y espalda, más altas que en el resto de saurópodos.',
    ),
    ChampionPreset(
      id: 'argentinosaurus',
      name: 'Argentinosaurus',
      scientificName: 'Argentinosaurus Huinculensis',
      type: ChampionType.titan,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 30-40 m\nPeso: 50-100 Toneladas',
      discovery: 'Neuquén, Patagonia argentina\n1989\nPor Guillermo Heredia',
      curiosity:
          'Es uno de los animales terrestres más grandes de la historia. Sin embargo, sus restos son escasos, por lo que no se puede estimar con precisión sus dimensiones.',
    ),
    ChampionPreset(
      id: 'alamosaurus',
      name: 'Alamosaurus',
      scientificName: 'Alamosaurus Sanjuanensis',
      type: ChampionType.titan,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 30 m\nPeso: 30-35 Toneladas',
      discovery:
          'Nuevo México, Estados Unidos\n1921\nPor Charles Whitney Gilmore, John Bernard Reeside y Charles Hazelius Sternberg',
      curiosity:
          'Es probablemente el dinosaurio más grande conocido hasta el momento en América del Norte. La mayoría de esqueletos encontrados pertenecen a ejemplares juveniles.',
    ),
    ChampionPreset(
      id: 'ultrasaurus',
      name: 'Ultrasaurus',
      scientificName: 'Ultrasaurus Tabriensis',
      type: ChampionType.titan,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight:
          'Longitud: 30 m\nAltura: 15 m\nPeso: 67 Toneladas',
      discovery: 'Kyongsang Pukdo, Corea del sur\n1983\nPor Haang Mook Kim',
      curiosity:
          'Cuando una colección de huesos de un dinosaurio desconocido fue encontrada en 1979 en Utah se anunció que se trataba del mayor dinosaurio descubierto hasta la fecha. Desafortunadamente, se trataban de huesos de Supersaurus y de Brachiosaurus.',
    ),

    // Wings
    ChampionPreset(
      id: 'eudimorphodon',
      name: 'Eudimorphodon',
      scientificName: 'Eudimorphodon Ranzii',
      type: ChampionType.wings,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 100 cm\nPeso: 10 Kg',
      discovery: 'Bérgamo, Italia\n1973\nPor Rocco Zambelli',
      curiosity:
          'Es uno de los pterosaurios más antiguos que se conocen. Al final de su larga cola tenía un diamante que utilizaba como timón para maniobrar en el aire.',
    ),
    ChampionPreset(
      id: 'peteinosaurus',
      name: 'Peteinosaurus',
      scientificName: 'Peteinosaurus Zambellii',
      type: ChampionType.wings,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight:
          'Longitud: 30-40 cm\nEvergadura alas: 60 cm\nPeso: 1,2 Kg',
      discovery: 'Cene, Italia\n1978\nPor Rupert Wild',
      curiosity:
          'Con apenas 60 cm, tenía una diminuta envergadura en comparación con los pterosaurios posteriores. Sus alas también eran mucho más cortas.',
    ),
    ChampionPreset(
      id: 'dimorphodon',
      name: 'Dimorphodon',
      scientificName: 'Dimorphodon Macronyx',
      type: ChampionType.wings,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 1 m\nEnvergadura alas: 1,4 m\nPeso: 2 Kg',
      discovery:
          'Dorset, Inglaterra\n1828\nPor Mary Anning\nNombrado por Richard Owen en 1859',
      curiosity:
          'Tenía un cráneo grande y voluminoso, cuyo peso se reducía gracias a grandes cavidades separadas por paredes óseas, estructura que recuerda a un puente. Tenía un cerebro muy pequeño.',
    ),
    ChampionPreset(
      id: 'anurognathus',
      name: 'Anurognathus',
      scientificName: 'Anurognathus Ammoni',
      type: ChampionType.wings,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 9 cm\nEnvergadura alas: 50 cm\nPeso: 40 g',
      discovery:
          'Eichstätt, Alemania\n1922\nDescrito por Ludwig Döderlein en 1923',
      curiosity:
          'Su nombre significa "sin cola y mandíbula" en griego, en referencia a su cola inusualmente corta en comparación a otros pterosaurios.',
    ),
    ChampionPreset(
      id: 'pterodactylus',
      name: 'Pterodactylus',
      scientificName: 'Pterodactylus Antiquus',
      type: ChampionType.wings,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 60 cm\nEnvergadura alas: 1,5 m\nPeso: 1-2 Kg',
      discovery:
          'Baviera, Alemania\n1780\nDescrito por Cosimo Alessandro Collini en 1784',
      curiosity:
          'Su nombre deriva de las palabras griega pteron (ala) y daktylos (dedo) y se refiere a la forma en la cual el ala se mantiene gracias a un único gran dedo.',
    ),
    ChampionPreset(
      id: 'archaeopteryx',
      name: 'Archaeopteryx',
      scientificName: 'Archaeopteryx Lithographica',
      type: ChampionType.wings,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight:
          'Longitud: 51 cm\nEnvergadura alas: 70 cm\nPeso: 1 Kg',
      discovery:
          'Langenaltheim, Alemania\n1860-1861\nPor Christian Erich Hermann von Meyer',
      curiosity:
          'Este animal podía crecer hasta los 50 cm. A pesar de su pequeño tamaño, presentaba amplias alas y era capaz de volar y planear.',
    ),
    ChampionPreset(
      id: 'quetzalcoatlus',
      name: 'Quetzalcoatlus',
      scientificName: 'Quetzalcoatlus Northropi',
      type: ChampionType.wings,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 5 m  \nEnvergadura alas: 10-11 m\nPeso: 200-250 Kg',
      discovery: 'Texas, Estados Unidos\n1971\nPor Douglas A. Lawson',
      curiosity:
          'Su nombre viene de la deidad azteca Quetzalcóatl, la serpiente emplumada. Fue uno de los animales voladores más grandes de la historia, pero se cree que cazaban en tierra y no en el aire.',
    ),
    ChampionPreset(
      id: 'tupandactylus',
      name: 'Tupandactylus',
      scientificName: 'Tupandactylus Imperator',
      type: ChampionType.wings,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Evergadura alas: 3-4 m\nPeso: 40-50 Kg',
      discovery:
          'Cuenca de Araripe, Brasil\nDescrito por Alexander Kellner y Diógenes de Almeida Campos en 2007',
      curiosity:
          'Su cresta puede haberse utilizada para defenderse de depredadores, señalizar y exhibir a otros tupandactylus, parecido a como los tucanes usan sus brillantes picos para enviar señales.',
    ),
    ChampionPreset(
      id: 'tropeognathus',
      name: 'Tropeognathus',
      scientificName: 'Tropeognathus Mesembrinus',
      type: ChampionType.wings,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 2,4 m\nEnvergaduras alas: 8,3-8,7 m\nPeso: 45 Kg',
      discovery: 'Ceará, Brasil\n1980\nDescrito por Peter Wellnhofer en 1987',
      curiosity:
          'Fue protagonista de un episodio de la serie de televisión "Walking with Dinosaurs", aunque en dicha serie fue identificado como un Ornithocheirus por error.',
    ),
    ChampionPreset(
      id: 'hatzegopteryx',
      name: 'Hatzegopteryx',
      scientificName: 'Hatzegopteryx Thambema',
      type: ChampionType.wings,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 4,5 m\nEnvergadura alas: 10-12 m\nPeso: 180-250 Kg',
      discovery:
          'Transilvania, Rumanía\nDescrito por Eric Buffetaut, Dan Grigorescu y Zoltan Csiki en 2002',
      curiosity:
          'Sus restos indican que estuvo entre los pterosaurios más grandes. En ausencia de terópodos grandes, Hatzegopteryx fue probablemente el superdepredador de la isla de Hațeg.',
    ),
    ChampionPreset(
      id: 'pteranodon',
      name: 'Pteranodon',
      scientificName: 'Pteranodon Longiceps',
      type: ChampionType.wings,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 2,6 m\nEnvergadura alas: 5,6 m\nPeso: 20-35 Kg',
      discovery: 'Kansas, Estados Unidos\n1870\nPor Othniel Charles Marsh',
      curiosity:
          'Cerca de 1000 especímenes han sido identificados, pero menos de la mitad están lo suficientemente completos como para dar información detallada sobre la atonomía del animal.',
    ),
    ChampionPreset(
      id: 'protoavis',
      name: 'Protoavis',
      scientificName: 'Protoavis Texensis',
      type: ChampionType.wings,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 35 cm\nPeso: 2-3 Kg',
      discovery: 'Texas, Estados Unidos\n1984\nPor Sankar Chatterjee',
      curiosity:
          'Sus restos desordenados se hallaban desparramados en un estrato sedimentario, lo que hace suponer que se trataría de una quimera, aunque su descubridor Sankar Chatterjee defendió que pertenecen a la misma especie.',
    ),

    // Claws
    ChampionPreset(
      id: 'coelophysis',
      name: 'Coelophysis',
      scientificName: 'Coelophysis Bauri',
      type: ChampionType.claws,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 3 m\nPeso: 15-20 Kg',
      discovery:
          'Estados Unidos\n1881\nPor David Baldwin\nNombrado por Edward Drinker Cope en 1889',
      curiosity:
          'Uno de los dinosaurios más antiguos. Su resistencia a las sequías hizo que esta especie triunfara sobre el resto de animales del Triásico.',
    ),
    ChampionPreset(
      id: 'procompsognathus',
      name: 'Procompsognathus',
      scientificName: 'Procompsognathus Triassicus',
      type: ChampionType.claws,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 75 cm\nPeso: 1 Kg',
      discovery: 'Württemberg, Alemania\nNombrado por Eberhard Fraas en 1913',
      curiosity:
          'Su nombre significa "antes de la mandíbula elegante", derivado del nombre de otro dinosaurio: Compsognathus. Aunque se trataba de un carnívoro pequeño y bípedo, la pobre conservación del único fósil conocido hace difícil determinar su clasificación exacta.',
    ),
    ChampionPreset(
      id: 'herrerasaurus',
      name: 'Herrerasaurus',
      scientificName: 'Herrerasaurus Ischigualastensis',
      type: ChampionType.claws,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight:
          'Longitud: 3-6 m\nAltura: 1,1 m\nPeso: 210-350 Kg',
      discovery:
          'Valle de la Luna, Argentina\n1959\nDescrito por Osvaldo Alfredo Reig en 1963',
      curiosity:
          'Durante muchos años la clasificación del Herrerasaurus no fue clara, ya que su descripción se basaba en restos escasos. Esto dio lugar a diversas hipótesis, llegando incluso a clasificarlo como un no dinosaurio.',
    ),
    ChampionPreset(
      id: 'ornitholestes',
      name: 'Ornitholestes',
      scientificName: 'Ornitholestes Hermanni',
      type: ChampionType.claws,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Longitud: 1,8 m\nAltura: 80 cm\nPeso: 11 Kg',
      discovery:
          'Wyoming, Estados Unidos\n1900\nPor Peter C. Kaisen, Paul Miller y Frederic Brewster Loomis',
      curiosity:
          'Durante años se pensó que tenían una pretuberancia encima del hocico debido a la forma del cráneo. A día de hoy, no se cree que fuera así.',
    ),
    ChampionPreset(
      id: 'guanlong',
      name: 'Guanlong',
      scientificName: 'Guanlong Wucaii',
      type: ChampionType.claws,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Longitud: 3 m\nAltura: 1,1 m\nPeso: 125 Kg',
      discovery: 'Dzungaria, China\n2006\nPor Xu Xing',
      curiosity:
          'A diferencia de los tiranosáuridos posteriores, este animal poseía tres dedos largos en sus manos, estaba cubierto por plumas y tenía una cresta en su cráneo.',
    ),
    ChampionPreset(
      id: 'marshosaurus',
      name: 'Marshosaurus',
      scientificName: 'Marshosaurus Bicentesimus',
      type: ChampionType.claws,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 4,5 m\nPeso: 200 Kg',
      discovery: 'Utah, Estados Unidos\n1960\nNombrado por Madsen en 1976',
      curiosity:
          'Sus brazos eran largos en comparación a otros terópodos, terminados en 3 dedos con garras que podía usar para cazar o para enfrentarse a otros depredadores.',
    ),
    ChampionPreset(
      id: 'compsognathus',
      name: 'Compsognathus',
      scientificName: 'Compsognathus Longipes',
      type: ChampionType.claws,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 70-140 cm\nPeso: 3 Kg',
      discovery:
          'Baviera, Alemania\n1850\nPor Joseph Oberndorfer\nDescrito por Johann A. Wagner en 1859',
      curiosity:
          'En la novela original de "Parque Jurásico" estos animales son los primeros en ser vistos y descritos por personajes del libro, además de matar a John Hammond paralizándolo con sus mordiscos. Realmente no tenían esta cualidad y su principal dieta consistía en insectos.',
    ),
    ChampionPreset(
      id: 'velociraptor',
      name: 'Velociraptor',
      scientificName: 'Velociraptor Mongoliensis',
      type: ChampionType.claws,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Longitud: 1,5 m\nAltura: 50 cm\nPeso: 14-20 Kg',
      discovery: 'Desierto de Gobi, Mongolia\n1923\nPor Peter Kaisen',
      curiosity:
          'Eran muy pequeños y estaban cubiertos por plumas, pero eran inteligentes y cazaban animales mucho más grandes que ellos.',
    ),
    ChampionPreset(
      id: 'utahraptor',
      name: 'Utahraptor',
      scientificName: 'Utahraptor Ostrommaysi',
      type: ChampionType.claws,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight:
          'Longitud: 5-7 m\nAltura: 1,5 m\nPeso: 0,3-1 Toneladas',
      discovery: 'Utah, Estados Unidos\n1975\nPor Jim Jensen',
      curiosity:
          'Los velociraptores de la saga "Parque Jurásico" están basados en estos raptores, aunque el Utahraptor presentaba plumas. ',
    ),
    ChampionPreset(
      id: 'troodon',
      name: 'Troodon',
      scientificName: 'Troodon Formosus',
      type: ChampionType.claws,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Longitud: 2,4 m\nAltura: 1 m\nPeso: 50 Kg',
      discovery:
          'Montana, Estados Unidos\n1855\nNombrado por Joseph Leidy en 1856',
      curiosity:
          'Es considerado como uno de los dinosaurios más inteligentes que jamás existieron. Debido a las escasas evidencias fósiles, a día de hoy se debate su clasificación como especie.',
    ),
    ChampionPreset(
      id: 'austroraptor',
      name: 'Austroraptor',
      scientificName: 'Austroraptor Cabazai',
      type: ChampionType.claws,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 6 m\nPeso: 300 Kg',
      discovery: 'Lamarque, Argentina\n2002\nPor Fernando Novas y equipo',
      curiosity:
          'Algo particularmente notable acerca de este animal eran sus cortos antebrazos, mucho más pequeños que los de la mayoría de los miembros de su grupo. Se cree que se alimentaba principalmente de peces.',
    ),
    ChampionPreset(
      id: 'pelecanimimus',
      name: 'Pelecanimimus',
      scientificName: 'Pelecanimimus Polyodon',
      type: ChampionType.claws,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Longitud: 2-2,5 m\nAltura: 1 m\nPeso: 17-25 Kg',
      discovery: 'Cuenca, España\n1993\nPor Armando Díaz Romeral',
      curiosity:
          'Es el Ornitomimosauriano más antiguo de los que se tenga noticia, además de poseer más dientes que cualquier otro miembro de dicha clasificación. Sus restos se encontraron en Cuenca, España.',
    ),
    ChampionPreset(
      id: 'archaeoraptor',
      name: 'Archaeoraptor',
      scientificName: 'Archaeoraptor Liaoningensis',
      type: ChampionType.claws,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 75-90 cm\nPeso: 1 Kg',
      discovery: 'China\n1999\nPor Christopher Sloan',
      curiosity:
          'El fósil se anunció como el eslabón perdido entre las aves y los dinosaurios terópodos, pero un estudio científico demostró definitivamente que era un fraude. Este escándalo atrajo atención hacia el tráfico ilegal de fósiles en China.',
    ),

    // Plates
    ChampionPreset(
      id: 'proganochelys',
      name: 'Proganochelys',
      scientificName: 'Proganochelys Quenstedtii',
      type: ChampionType.plates,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Tamaño: 1 m\nPeso: 18 Kg',
      discovery: 'Baden-Wurtemberg, Alemania\n1887\nPor Georg Baur',
      curiosity:
          'Es una de las tortugas más antiguas que se ha descubierto hasta la fecha, aunque algunos científicos sostienen que era muy avanzada y que hubo tortugas aún más primitivas.',
    ),
    ChampionPreset(
      id: 'desmatosuchus',
      name: 'Desmatosuchus',
      scientificName: 'Desmatosuchus Spurensis',
      type: ChampionType.plates,
      period: MesozoicPeriod.triassic,
      estimatedSizeAndWeight: 'Longitud: 5 m\nAltura: 1,5 m\nPeso: 570 Kg',
      discovery: 'Texas y arizona, Estados Unidos\n1920\nPor E. C. Case',
      curiosity:
          'Poseía un cuerpo acorazado y una cabeza que recuerda vagamente a la de un cerdo. También tenía dos filas de espinas a lo largo de los lados de su espalda. Las mayores espinas, situadas sobre los hombros, medían 45 centímetros de largo.',
    ),
    ChampionPreset(
      id: 'stegosaurus',
      name: 'Stegosaurus',
      scientificName: 'Stegosaurus Ungulatus',
      type: ChampionType.plates,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 9 m\nPeso: 3,8-7 Toneladas',
      discovery: 'Wyoming, Estados Unidos\n1879\nPor Othniel Charles Marsh',
      curiosity:
          'Su cerebro era tan pequeño que se llegó a teorizar que tenía un segundo cerebro en la cola. Eran capaces de bombear sangre a sus placas para intimidar a los depredadores con colores vivos.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(name: 'Lanza ósea'),
        BattleGesture.paper: ChampionMovePreset(
          name: 'Placas de sangre',
          effectDescription: 'Intimidación',
          isCritical: true,
        ),
        BattleGesture.scissors: ChampionMovePreset(name: 'Posición defensiva'),
      },
    ),
    ChampionPreset(
      id: 'kentrosaurus',
      name: 'Kentrosaurus',
      scientificName: 'Kentrosaurus Aethiopicus',
      type: ChampionType.plates,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 4,5 m\nPeso: 1-3 Toneladas',
      discovery: 'Tanzania\n1909\nDescrito por Edwin Hennig en 1915',
      curiosity:
          'Tenía una espina larga en cada hombro. Los huesos del muslo vienen en dos tipos diferentes, lo que sugiere que un sexo era más grande y robusto que el otro.',
    ),
    ChampionPreset(
      id: 'dracopelta',
      name: 'Dracopelta',
      scientificName: 'Dracopelta Zbyszewskii',
      type: ChampionType.plates,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 1 m\nPeso: 200-300 Kg',
      discovery: 'Mafra, Portugal\n1980\nDescrito por Peter Galton',
      curiosity:
          'Es el primer anquilosáurido reconocido del Jurásico tardío y los restos pertenecen a unos de los géneros más antiguos referidos a Ankylosauria.',
    ),
    ChampionPreset(
      id: 'gigantspinosaurus',
      name: 'Gigantspinosaurus',
      scientificName: 'Gigantspinosaurus Sichuanensis',
      type: ChampionType.plates,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 4,2 m\nPeso: 700 Kg',
      discovery: 'Sichuan, China\n1985\nPor Ouyang Hui',
      curiosity:
          'Tenía una apariencia distintiva con placas dorsales pequeñas y enormes espinas en los hombros.',
    ),
    ChampionPreset(
      id: 'spicomellus',
      name: 'Spicomellus',
      scientificName: 'Spicomellus Afer',
      type: ChampionType.plates,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Tamaño: 3 m\nPeso: 150-300 Kg',
      discovery:
          'Fès-Meknès, Marruecos\nAdquirido en 2019\nDescrito por Susana Maidment en 2021',
      curiosity:
          'Debido a la fusión de las espinas dorsales al hueso en vez de ser sujetadas a tejido muscular, es probable que presentara dificultades al moverse.',
    ),
    ChampionPreset(
      id: 'scutellosaurus',
      name: 'Scutellosaurus',
      scientificName: 'Scutellosaurus Lawleri',
      type: ChampionType.plates,
      period: MesozoicPeriod.jurassic,
      estimatedSizeAndWeight: 'Longitud: 1,2 m\nAltura: 50 cm\nPeso: 3 Kg',
      discovery: 'Colorado, Estados Unidos\n1981\nPor Edwin H. Colbert',
      curiosity:
          'Era de constitución ligera y probablemente capaz de caminar sobre sus patas traseras. Tenía una cola muy larga, posiblemente para contrarestar el peso de su cuerpo.',
    ),
    ChampionPreset(
      id: 'ankylosaurus',
      name: 'Ankylosaurus',
      scientificName: 'Ankylosaurus Magniventris',
      type: ChampionType.plates,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 6-8 m\nPeso: 4,8-8 Toneladas',
      discovery: 'Montana, Estados Unidos\n1906\nPor Barnum Brown',
      curiosity:
          'Su cráneo estaba también cubierto por placas, haciéndolo uno de los dinosaurios mejor protegidos de los ataques de depredadores. La maza en su cola era capaz de romper huesos de un solo golpe.',
      moveOverrides: {
        BattleGesture.rock: ChampionMovePreset(
          name: 'Martillazo',
          effectDescription: 'Daño + Hueso roto',
          isCritical: true,
        ),
        BattleGesture.paper: ChampionMovePreset(name: 'Escamas dentadas'),
        BattleGesture.scissors: ChampionMovePreset(name: 'Posición defensiva'),
      },
    ),
    ChampionPreset(
      id: 'gastonia',
      name: 'Gastonia',
      scientificName: 'Gastonia Burgei',
      type: ChampionType.plates,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5 m\nPeso: 1,9 Toneladas',
      discovery:
          'Utah, Estados Unidos\n1989\nDescrito por James Kirkland en 1998',
      curiosity:
          'Debe su nombre a su descubridor: Robert Gaston. Su cola era moderadamente larga y carecía de una porra.',
    ),
    ChampionPreset(
      id: 'saichania',
      name: 'Saichania',
      scientificName: 'Saichania Chulsanensis',
      type: ChampionType.plates,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 6,6 m\nPeso: 2 Toneladas',
      discovery:
          'Desierto de Gobi, Mongolia\n1970-1971\nDescrito por Teresa Maryańska en 1977',
      curiosity:
          'Estaba fuertemente protegido por una armadura que cubría no solo su parte superior, sino también la ventral, algo solo conocido en este dinosaurio.',
    ),
    ChampionPreset(
      id: 'sauropelta',
      name: 'Sauropelta',
      scientificName: 'Sauropelta Edwardsorum',
      type: ChampionType.plates,
      period: MesozoicPeriod.cretaceous,
      estimatedSizeAndWeight: 'Tamaño: 5,2 m\nPeso: 1,5 Toneladas',
      discovery: 'Montana, Estados Unidos\n1930\nPor Barnum Brown',
      curiosity:
          'Su único punto débil era su descubierto abdomen, así que se defendía dejándose caer y clavando sus patas al suelo para que no lo pudieran voltear.',
    ),
    ChampionPreset(
      id: 'polacanthoides',
      name: 'Polacanthoides',
      scientificName: 'Polacanthoides Ponderosus',
      type: ChampionType.plates,
      period: MesozoicPeriod.chimera,
      estimatedSizeAndWeight: 'Tamaño: 5-6 m\nPeso: 2 Toneladas',
      discovery:
          'Isla de Wight, Inglaterra\nDescrito por Ferenc Nopcsa en 1928',
      curiosity:
          'Posiblemente sus restos están formados por material mezclado de Hylaeosaurus y Polacanthus. Aunque Carpenter propuso que la escápula del ejemplar demuestra que es válido, es considerado por la mayoría de los paleontólogos como un dinosaurio dudoso.',
    ),
  ];

  static final Map<String, ChampionPreset> byId = Map.unmodifiable({
    for (final preset in all) preset.id: preset,
  });

  static ChampionPreset? findById(String id) => byId[id];

  static Iterable<ChampionPreset> forType(ChampionType type) =>
      all.where((preset) => preset.type == type);

  static Iterable<ChampionPreset> forPeriod(MesozoicPeriod period) =>
      all.where((preset) => preset.period == period);
}
