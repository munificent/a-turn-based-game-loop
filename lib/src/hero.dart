library a_turn_based_game_loop.src.hero;

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import 'actor.dart';
import 'game.dart';

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  Action _nextAction;

  Hero(Game game, Vec pos) : super(game, pos);

  get appearance => "hero";

  bool get needsInput => _nextAction == null;

  Action onGetAction() {
    var action = _nextAction;
    _nextAction = null;
    return action;
  }

  void setNextAction(Action action) {
    _nextAction = action;
  }
}

