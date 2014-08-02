library a_turn_based_game_loop.src.monster;

import 'package:piecemeal/piecemeal.dart';

import 'a_star.dart';
import 'action.dart';
import 'actor.dart';
import 'energy.dart';
import 'game.dart';

/// A single kind of [Monster] in the game.
class Breed {
  /// Untyped so the engine isn't coupled to how monsters appear.
  final appearance;

  /// The breed's speed, relative to normal. Ranges from `-6` (slowest) to `6`
  /// (fastest) where `0` is normal speed.
  final int speed;

  final bool canOpenDoors;

  Breed(this.appearance, this.speed, this.canOpenDoors);
}

class Monster extends Actor {
  final Breed breed;

  get appearance => breed.appearance;

  Monster(Game game, this.breed, Vec pos) : super(game, pos);

  int get speed => Energy.NORMAL_SPEED + breed.speed;

  Action onGetAction() {
    // Now that we know what the monster *wants* to do, reconcile it with what
    // they're able to do.
    var walkDir = _findMeleePath();
    if (walkDir == null) walkDir = Direction.NONE;
    return new WalkAction(walkDir);
  }

  Vec _findMeleePath() {
    // Try to pathfind towards the hero.
    var path = AStar.findPath(game, pos, game.hero.pos, 20);

    if (path.length == 0) return null;

    var tile = game.tiles[pos + path.direction];
    if (tile == Tile.WALL) return null;
    if (tile == Tile.CLOSED_DOOR && !breed.canOpenDoors) return null;

    // Don't walk into another monster.
    var actor = game.actorAt(pos + path.direction);
    if (actor != null && actor != game.hero) return null;
    return path.direction;
  }
}
