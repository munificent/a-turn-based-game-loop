library a_turn_based_game_loop.src.a_star;

import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import 'game.dart';

class PathResult {
  /// The direction to move on the first step of the path.
  final Direction direction;

  /// The total number of steps in the path.
  final int length;

  PathResult(this.direction, this.length);
}

/// A* pathfinding algorithm.
class AStar {
  /// When calculating pathfinding, how much it "costs" to move one step on
  /// an open floor tile.
  static final FLOOR_COST = 10;

  /// When calculating pathfinding, how much it costs to move one step on a
  /// tile already occupied by an actor. For pathfinding, we consider occupied
  /// tiles as accessible but expensive. The idea is that by the time the
  /// pathfinding monster gets there, the occupier may have moved, so the tile
  /// is "sorta" empty, but still not as desirable as an actually empty tile.
  static final OCCUPIED_COST = 40;

  /// When calculating pathfinding, how much it costs cross a currently-closed
  /// door. Instead of considering them completely impassable, we just have them
  /// be expensive, because it still may be beneficial for the monster to get
  /// closer to the door (for when the hero opens it later).
  static final DOOR_COST = 80;

  /// When applying the pathfinding heuristic, straight steps (NSEW) are
  /// considered a little cheaper than diagonal ones so that straighter paths
  /// are preferred over equivalent but uglier zig-zagging ones.
  static final STRAIGHT_COST = 9;

  /// Tries to find a path from [start] to [end], searching up to [maxLength]
  /// steps from [start]. Returns the [Direction] of the first step from [start]
  /// along that path (or [Direction.NONE] if it determines there is no path
  /// possible.
  static Direction findDirection(Game game, Vec start, Vec end, int maxLength) {
    var path = _findPath(game, start, end, maxLength);
    if (path == null) return Direction.NONE;

    while (path.parent != null && path.parent.parent != null) {
      path = path.parent;
    }

    return path.direction;
  }

  static PathResult findPath(Game game, Vec start, Vec end, int maxLength) {
    var path = _findPath(game, start, end, maxLength);
    if (path == null) return new PathResult(Direction.NONE, 0);

    var length = 1;
    while (path.parent != null && path.parent.parent != null) {
      path = path.parent;
      length++;
    }

    return new PathResult(path.direction, length);
  }

  static _PathNode _findPath(Game game, Vec start, Vec end, int maxLength) {
    // TODO: More optimal data structure.
    var startPath = new _PathNode(null, Direction.NONE,
        start, 0, heuristic(start, end));
    var open = <_PathNode>[startPath];
    var closed = new Set<Vec>();

    while (open.length > 0) {
      // Pull out the best potential candidate.
      var current = open.removeLast();

      if ((current.pos == end) ||
          (current.cost > FLOOR_COST * maxLength)) {
        // Found the path.
        return current;
      }

      closed.add(current.pos);

      for (var dir in Direction.ALL) {
        var neighbor = current.pos + dir;

        // Skip impassable tiles.
        if (game.tiles[neighbor] == Tile.WALL) continue;

        // Given how far the current tile is, how far is each neighbor?
        var stepCost = FLOOR_COST;
        if (game.actorAt(neighbor) != null) {
          stepCost = OCCUPIED_COST;
        }

        var cost = current.cost + stepCost;

        // See if we just found a better path to a tile we're already
        // considering. If so, remove the old one and replace it (below) with
        // this new better path.
        var inOpen = false;

        for (var i = 0; i < open.length; i++) {
          var alreadyOpen = open[i];
          if (alreadyOpen.pos == neighbor) {
            if (alreadyOpen.cost > cost) {
              open.removeAt(i);
              i--;
            } else {
              inOpen = true;
            }
            break;
          }
        }

        var inClosed = closed.contains(neighbor);

        // TODO: May need to do the above check on the closed set too if
        // we use inadmissable heuristics.

        // If we have a new path, add it.
        if (!inOpen && !inClosed) {
          var guess = cost + heuristic(neighbor, end);
          var path = new _PathNode(current, dir, neighbor, cost, guess);

          // Insert it in sorted order (such that the best node is at the *end*
          // of the list for easy removal).
          bool inserted = false;
          for (var i = open.length - 1; i >= 0; i--) {
            if (open[i].guess > guess) {
              open.insert(i + 1, path);
              inserted = true;
              break;
            }
          }

          // If we didn't find a node to put it after, put it at the front.
          if (!inserted) open.insert(0, path);
        }
      }
    }

    // No path.
    return null;
  }

  /// The estimated cost from [pos] to [end].
  static int heuristic(Vec pos, Vec end) {
    // A simple heuristic would just be the kingLength. The problem is that
    // diagonal moves are as "fast" as straight ones, which means many
    // zig-zagging paths are as good as one that looks "straight" to the player.
    // But they look wrong. To avoid this, we will estimate straight steps to
    // be a little cheaper than diagonal ones. This avoids paths like:
    //
    // ...*...
    // s.*.*.g
    // .*...*.
    final offset = (end - pos).abs();
    final numDiagonal = math.min(offset.x, offset.y);
    final numStraight = math.max(offset.x, offset.y) - numDiagonal;
    return (numDiagonal * FLOOR_COST) +
           (numStraight * STRAIGHT_COST);
  }
}

class _PathNode {
  final _PathNode parent;
  final Direction direction;
  final Vec pos;

  /// The cost to get to this node from the starting point. This is roughly the
  /// distance, but may be a little different if we start weighting tiles in
  /// interesting ways (i.e. make it more expensive for light-abhorring
  /// monsters to walk through lit tiles).
  final int cost;

  /// The guess as to the total cost from the start node to the end node going
  /// along this path. In other words, this is [cost] plus the heuristic.
  final int guess;

  _PathNode(this.parent, this.direction, this.pos, this.cost, this.guess);
}
