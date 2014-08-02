library a_turn_based_game_loop.src.game;

import 'package:piecemeal/piecemeal.dart';

import 'actor.dart';
import 'monster.dart';
import 'hero.dart';

class Tile {
  static const FLOOR = const Tile(0);
  static const WALL = const Tile(1);
  static const CLOSED_DOOR = const Tile(2);
  static const OPEN_DOOR = const Tile(3);

  final int _type;

  const Tile(this._type);

  bool get canWalk => this == Tile.FLOOR || this == Tile.OPEN_DOOR;
}

/// Root class for the game engine. All game state is contained within this.
class Game {
  final Array2D<Tile> tiles;

  bool spendEnergyOnFailure = true;
  bool stopAfterEveryProcess = false;

  final actors = <Actor>[];
  int _currentActorIndex = 0;

  Hero hero;

  int get width => tiles.width;
  int get height => tiles.height;

  Actor get currentActor => actors[_currentActorIndex];

  Game(int width, int height)
      : tiles = new Array2D<Tile>(width, height, Tile.FLOOR) {
    var map = [
      '##################################################',
      '#........................................#.#.....#',
      '#........................................#...#.#.#',
      '#........................................#.###.#.#',
      '#........................................#.#...#.#',
      '#..############..........................###.#####',
      '#..#..........#..................................#',
      '#..#..........#..........................#######.#',
      '#..#.....................................#.......#',
      '#..#..........#..........................#.#######',
      '#..#..........#..........................#.#.....#',
      '#..############..........................#.#####.#',
      '#........................................#...#...#',
      '#........................................#.#...#.#',
      '##################################################'
    ];

    for (var y = 0; y < map.length; y++) {
      for (var x = 0; x < map[0].length; x++) {
        tiles.set(x, y, map[y][x] == '#' ? Tile.WALL : Tile.FLOOR);
      }
    }

    hero = new Hero(this, findOpenTile());
    actors.add(hero);
  }

  GameResult update() {
    var gameResult = new GameResult();

    while (true) {
      var actor = currentActor;

      // If we are still waiting for input for the actor, just return (again).
      if (actor.energy.canTakeTurn && actor.needsInput) return gameResult;

      gameResult.madeProgress = true;

      // If we get here, all pending actions are done, so advance to the next
      // tick until an actor moves.
      var action;
      while (action == null) {
        var actor = currentActor;

        if (actor.energy.canTakeTurn || actor.energy.gain(actor.speed)) {
          // If the actor can move now, but needs input from the user, just
          // return so we can wait for it.
          if (actor.needsInput) return gameResult;

          action = actor.getAction();
        } else {
          // This actor doesn't have enough energy yet, so move on to the next.
          advanceActor();

          if (stopAfterEveryProcess) return gameResult;
        }
      }

      // Cascade through the alternates until we hit bottom out.
      var result = action.perform(gameResult);
      while (result.alternative != null) {
        action = result.alternative;
        result = action.perform(gameResult);
      }

      if (spendEnergyOnFailure || result.succeeded) {
        action.actor.finishTurn(action);
        advanceActor();
      }
    }
  }

  addMonster(Breed breed) {
    actors.add(new Monster(this, breed, findOpenTile()));
  }

  void advanceActor() {
    _currentActorIndex = (_currentActorIndex + 1) % actors.length;
  }

  Actor actorAt(Vec pos) {
    return actors.firstWhere((actor) => actor.pos == pos, orElse: () => null);
  }

  // TODO: This is hackish and may fail to terminate.
  /// Selects a random passable tile that does not have an [Actor] on it.
  Vec findOpenTile() {
    while (true) {
      var pos = rng.vecInRect(tiles.bounds);

      if (!tiles[pos].canWalk) continue;
      if (actorAt(pos) != null) continue;

      return pos;
    }
  }
}

/// Each call to [Game.update()] will return a [GameResult] object that tells
/// the UI what happened during that update and what it needs to do.
class GameResult {
  /// The "interesting" events that occurred in this update.
  final List<Event> events;

  /// Whether or not any game state has changed. If this is `false`, then no
  /// game processing has occurred (i.e. the game is stuck waiting for user
  /// input for the [Hero]).
  bool madeProgress = false;

  /// Returns `true` if the game state has progressed to the point that a change
  /// should be shown to the user.
  bool get needsRefresh => madeProgress || events.length > 0;

  GameResult()
  : events = <Event>[];
}

/// Describes a single "interesting" thing that occurred during a call to
/// [Game.update()]. In general, events correspond to things that a UI is likely
/// to want to display visually in some form.
class Event {
  final String type;
  final Vec pos;

  Event(this.type, this.pos);
}
