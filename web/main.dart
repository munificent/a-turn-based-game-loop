library a_turn_based_game_loop.web.main;

import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:a_turn_based_game_loop/src/game.dart';
import 'package:a_turn_based_game_loop/src/game_screen.dart';
import 'package:a_turn_based_game_loop/src/monster.dart';

main() {
  var sameSpeedUI = makeDemo("same-speed", false, (game) {
    game.addMonster(new Breed("slug", 0, false));
    game.addMonster(new Breed("troll", 0, false));
    game.addMonster(new Breed("wizard", 0, false));
  });

  var varySpeedUI = makeDemo("speed-bars", true, (game) {
    game.stopAfterEveryProcess = true;
    game.addMonster(new Breed("slug", -3, false));
    game.addMonster(new Breed("troll", -2, false));
    game.addMonster(new Breed("wizard", -1, false));
  });

  var safeFailUI = makeDemo("safe-fail", false, (game) {
    game.spendEnergyOnFailure = false;
    game.addMonster(new Breed("slug", -2, false));
    game.addMonster(new Breed("troll", -1, false));
    game.addMonster(new Breed("wizard", 0, false));
  });

  var alternate = makeDemo("alternate", false, (game) {
    game.spendEnergyOnFailure = false;
    game.tiles.set(14, 8, Tile.CLOSED_DOOR);
    game.addMonster(new Breed("slug", -2, false));
    game.addMonster(new Breed("troll", -1, false));
    game.addMonster(new Breed("wizard", 0, true));
  });

  var t = 0;
  tick(time) {
    t = (t + 1) % 3;
    if (t == 0) {
      varySpeedUI.tick();
    }

    sameSpeedUI.tick();
    safeFailUI.tick();
    alternate.tick();

    html.window.requestAnimationFrame(tick);
  }

  html.window.requestAnimationFrame(tick);
}

UserInterface makeDemo(String id, bool showSpeeds, callback(Game game)) {
  var element = html.querySelector("canvas#$id") as html.CanvasElement;

  var height = 15;
  if (showSpeeds) height = 20;
  var terminal = new RetroTerminal(50, height, element, "/image/dos-short.png",
      charWidth: 9, charHeight: 13);
  var keyboard = new Keyboard(element);
  var ui = new UserInterface(keyboard, terminal);

  var gameScreen = new GameScreen(showSpeeds: showSpeeds);

  callback(gameScreen.game);

  ui.push(gameScreen);

  element.onFocus.listen((_) {
    gameScreen.focus = true;
  });

  element.onBlur.listen((_) {
    gameScreen.focus = false;
  });

  return ui;
}