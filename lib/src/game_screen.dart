library a_turn_based_game_loop.src.game_screen;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import 'actor.dart';
import 'energy.dart';
import 'game.dart';

final floor = new Glyph('.', Color.GRAY);
final wall = new Glyph('#', Color.WHITE, Color.GRAY);

final tiles = {
  Tile.FLOOR: new Glyph('.', Color.GRAY),
  Tile.WALL: new Glyph('#', Color.WHITE, Color.GRAY),
  Tile.OPEN_DOOR: new Glyph('_', Color.BROWN),
  Tile.CLOSED_DOOR: new Glyph("'", Color.GOLD, Color.BROWN),
};

final monsters = {
  "hero": new Glyph('@', Color.WHITE),
  "slug": new Glyph('S', Color.LIGHT_GREEN),
  "troll": new Glyph('T', Color.ORANGE),
  "wizard": new Glyph('W', Color.BLUE)
};

final speedColors = [
  Color.BLUE,
  Color.AQUA,
  Color.GREEN,
  Color.YELLOW,
  Color.GOLD,
  Color.ORANGE,
];

class GameScreen extends Screen {
  final Game game;
  final bool showSpeeds;

  List<Effect> effects = <Effect>[];

  GameScreen({bool showSpeeds})
      : game = new Game(50, 15),
        showSpeeds = showSpeeds;

  bool _focus = false;
  void set focus(bool value) {
    _focus = value;
    dirty();
  }

  bool handleInput(Keyboard keyboard) {
    var action;

    // TODO: Arrow keys.
    switch (keyboard.lastPressed) {
      case KeyCode.UP: action = new WalkAction(Direction.N); break;
      case KeyCode.DOWN: action = new WalkAction(Direction.S); break;
      case KeyCode.LEFT: action = new WalkAction(Direction.W); break;
      case KeyCode.RIGHT: action = new WalkAction(Direction.E); break;

      case KeyCode.I: action = new WalkAction(Direction.NW); break;
      case KeyCode.O: action = new WalkAction(Direction.N); break;
      case KeyCode.P: action = new WalkAction(Direction.NE); break;
      case KeyCode.K: action = new WalkAction(Direction.W); break;
      case KeyCode.L: action = new WalkAction(Direction.NONE); break;
      case KeyCode.SEMICOLON: action = new WalkAction(Direction.E); break;
      case KeyCode.COMMA: action = new WalkAction(Direction.SW); break;
      case KeyCode.PERIOD: action = new WalkAction(Direction.S); break;
      case KeyCode.SLASH: action = new WalkAction(Direction.SE); break;

      case KeyCode.T: action = new TeleportAction(); break;
      case KeyCode.C: action = new CloseDoorAction(); break;
    }

    if (action != null) {
      game.hero.setNextAction(action);
    }

    return true;
  }

  void update() {
    if (effects.length > 0) dirty();

    var result = game.update();

    for (final event in result.events) {
      switch (event.type) {
        case "hit":
          effects.add(new Effect(event.pos,
              new Glyph('*', Color.RED, Color.DARK_RED), 10));
          break;
        case "bonk":
          effects.add(new Effect(event.pos,
              new Glyph('X', Color.ORANGE, Color.DARK_ORANGE), 5));
          break;
      }
    }

    if (result.needsRefresh) dirty();

    effects = effects.where((effect) => effect.update(game)).toList();
  }

  void render(Terminal terminal) {
    terminal.clear();

    // Draw the stage.
    for (int y = 0; y < game.height; y++) {
      for (int x = 0; x < game.width; x++) {
        terminal.drawGlyph(x, y, tiles[game.tiles.get(x, y)]);
      }
    }

    var hero = game.hero;

    // Draw the actors.
    for (final actor in game.actors) {
      terminal.drawGlyph(actor.pos.x, actor.pos.y, monsters[actor.appearance]);
    }

    // Draw the effects.
    for (final effect in effects) {
      effect.render(terminal);
    }

    if (!_focus) {
      var message = "[Click to focus]";
      terminal.writeAt((terminal.width - message.length) ~/ 2, 14,
          message, Color.YELLOW);
    }

    if (!showSpeeds) return;

    // Draw the energy bars.
    var y = 16;
    for (var actor in game.actors) {
      if (game.currentActor == actor) {
        terminal.writeAt(0, y, ">");
      }

      terminal.drawGlyph(2, y, monsters[actor.appearance]);
      terminal.writeAt(4, y, actor.appearance);

      terminal.writeAt(36, y, "|", Color.GRAY);

      var barWidth = Energy.GAINS[actor.speed] * 2;
      var bar = ("[" + "=" * (barWidth - 2) + "]") * 16;

      terminal.writeAt(12, y,
          bar.substring(0, _energyToPixel(actor.energy.energy)),
          speedColors[actor.speed]);

      y++;
    }
  }

  int _energyToPixel(int energy) => energy * 2;
}

class Effect {
  final Vec pos;
  final Glyph glyph;
  int life;

  Effect(this.pos, this.glyph, this.life);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Terminal terminal) {
    terminal.drawGlyph(pos.x, pos.y, glyph);
  }
}
