library a_turn_based_game_loop.src.action_base;

import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

import 'actor.dart';
import 'game.dart';
import 'monster.dart';

abstract class Action {
  Actor _actor;
  Game _game;
  GameResult _gameResult;

  Game get game => _game;
  Actor get actor => _actor;

  void bind(Actor actor) {
    assert(_actor == null);

    _actor = actor;
    _game = actor.game;
  }

  ActionResult perform(GameResult gameResult) {
    assert(_actor != null); // Action should be bound already.

    _gameResult = gameResult;
    return onPerform();
  }

  ActionResult onPerform();

  void addEvent(Event event) {
    _gameResult.events.add(event);
  }

  ActionResult alternate(Action action) {
    action.bind(_actor);
    return new ActionResult.alternate(action);
  }
}

class ActionResult {
  static final SUCCESS = const ActionResult(succeeded: true);
  static final FAILURE = const ActionResult(succeeded: false);

  /// An alternate [Action] that should be performed instead of the one that
  /// failed to perform and returned this. For example, when the [Hero] walks
  /// into a closed door, the [WalkAction] will fail (the door is closed) and
  /// return an alternate [OpenDoorAction] instead.
  final Action alternative;

  /// `true` if the [Action] was successful and energy should be consumed.
  final bool succeeded;

  const ActionResult({this.succeeded})
  : alternative = null;

  const ActionResult.alternate(this.alternative)
  : succeeded = false;
}

class WalkAction extends Action {
  final Vec offset;

  WalkAction(this.offset);

  ActionResult onPerform() {
    final pos = actor.pos + offset;

    // See if there is an actor there.
    final target = game.actorAt(pos);
    if (target != null && target != actor) {
      return alternate(new AttackAction(target));
    }

    // See if we can walk there.
    var tile = game.tiles[pos];
    switch (tile) {
      case Tile.WALL:
        addEvent(new Event("bonk", pos));
        return ActionResult.FAILURE;

      case Tile.CLOSED_DOOR:
        return alternate(new OpenDoorAction(pos));
    }

    actor.pos = pos;
    return ActionResult.SUCCESS;
  }
}

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  ActionResult onPerform() {
    addEvent(new Event("hit", defender.pos));

    if (defender is Monster) {
      defender.pos = game.findOpenTile();
    }

    return ActionResult.SUCCESS;
  }
}

class TeleportAction extends Action {
  TeleportAction();

  ActionResult onPerform() {
    actor.pos = game.findOpenTile();
    return ActionResult.SUCCESS;
  }
}

class OpenDoorAction extends Action {
  final Vec doorPos;

  OpenDoorAction(this.doorPos);

  ActionResult onPerform() {
    game.tiles[doorPos] = Tile.OPEN_DOOR;
    return ActionResult.SUCCESS;
  }
}

class CloseDoorAction extends Action {
  ActionResult onPerform() {
    for (var dir in Direction.ALL) {
      if (game.tiles[actor.pos + dir] == Tile.OPEN_DOOR) {
        game.tiles[actor.pos + dir] = Tile.CLOSED_DOOR;
      }
    }
    return ActionResult.SUCCESS;
  }
}
