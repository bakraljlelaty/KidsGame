import '../../shared/models/game_id.dart';

/// Which simple original drawing a sticker uses (see StickerArtPainter).
enum StickerArt {
  carrot,
  bunny,
  banana,
  bubble,
  fish,
  starfish,
  sockRed,
  sockStriped,
  sockDotted,
  soap,
  duck,
  sponge,
  rocket,
  planet,
  star,
  moon,
  teddy,
  lamp,
}

class StickerDef {
  const StickerDef({
    required this.id,
    required this.gameId,
    required this.art,
  });

  final String id;
  final GameId gameId;
  final StickerArt art;
}

/// All collectible stickers. Earned through participation: each mini-game
/// completion unlocks the next sticker of that game.
class StickerCatalog {
  StickerCatalog._();

  static const List<StickerDef> all = [
    StickerDef(
        id: 'feed_carrot', gameId: GameId.feedAnimals, art: StickerArt.carrot),
    StickerDef(
        id: 'feed_bunny', gameId: GameId.feedAnimals, art: StickerArt.bunny),
    StickerDef(
        id: 'feed_banana', gameId: GameId.feedAnimals, art: StickerArt.banana),
    StickerDef(
        id: 'pop_bubble', gameId: GameId.bubblePop, art: StickerArt.bubble),
    StickerDef(id: 'pop_fish', gameId: GameId.bubblePop, art: StickerArt.fish),
    StickerDef(
        id: 'pop_starfish',
        gameId: GameId.bubblePop,
        art: StickerArt.starfish),
    StickerDef(
        id: 'sock_red', gameId: GameId.dancingSocks, art: StickerArt.sockRed),
    StickerDef(
        id: 'sock_striped',
        gameId: GameId.dancingSocks,
        art: StickerArt.sockStriped),
    StickerDef(
        id: 'sock_dotted',
        gameId: GameId.dancingSocks,
        art: StickerArt.sockDotted),
    StickerDef(id: 'pig_soap', gameId: GameId.muddyPig, art: StickerArt.soap),
    StickerDef(id: 'pig_duck', gameId: GameId.muddyPig, art: StickerArt.duck),
    StickerDef(
        id: 'pig_sponge', gameId: GameId.muddyPig, art: StickerArt.sponge),
    StickerDef(
        id: 'rocket_ship',
        gameId: GameId.buildRocket,
        art: StickerArt.rocket),
    StickerDef(
        id: 'rocket_planet',
        gameId: GameId.buildRocket,
        art: StickerArt.planet),
    StickerDef(
        id: 'rocket_star', gameId: GameId.buildRocket, art: StickerArt.star),
    StickerDef(
        id: 'bed_moon', gameId: GameId.bedtimeRoutine, art: StickerArt.moon),
    StickerDef(
        id: 'bed_teddy', gameId: GameId.bedtimeRoutine, art: StickerArt.teddy),
    StickerDef(
        id: 'bed_lamp', gameId: GameId.bedtimeRoutine, art: StickerArt.lamp),
  ];

  static List<StickerDef> forGame(GameId id) =>
      all.where((s) => s.gameId == id).toList(growable: false);

  static StickerDef? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
