library a_turn_based_game_loop.src.actor;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import 'energy.dart';
import 'game.dart';

/// An active entity in the game. Includes monsters and the hero.
abstract class Actor {
  Vec pos;

  final Game game;
  final Energy energy = new Energy();

  Actor(this.game, this.pos);

  bool get needsInput => false;

  /// Gets the actor's current speed, taking into any account any active
  /// [Condition]s.
  int get speed => Energy.NORMAL_SPEED;

  Action getAction() {
    final action = onGetAction();
    if (action != null) action.bind(this);
    return action;
  }

  Action onGetAction();

  void finishTurn(Action action) {
    energy.spend();
  }
}
