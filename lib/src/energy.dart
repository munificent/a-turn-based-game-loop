library a_turn_based_game_loop.src.energy;

/// Energy is used to control the rate that actors move relative to other
/// actors. Each game turn, every actor will accumulate energy based on their
/// speed. When it reaches a threshold, that actor can take a turn.
class Energy {
  static final MIN_SPEED    = 0;
  static final NORMAL_SPEED = 3;
  static final MAX_SPEED    = 5;

  static final ACTION_COST = 12;

  // How much energy is gained each game turn for each speed.
  static final GAINS = const [
    2,     // 1/3 normal speed
    3,     // 1/2
    4,
    6,     // normal speed
    9,
    12,    // 2x normal speed
  ];

  static num ticksAtSpeed(int speed) {
    return ACTION_COST / GAINS[NORMAL_SPEED + speed];
  }

  int energy = 0;

  bool get canTakeTurn => energy >= ACTION_COST;

  /// Advances one game turn and gains an appropriate amount of energy. Returns
  /// `true` if there is enough energy to take a turn.
  bool gain(int speed) {
    energy += GAINS[speed];
    return canTakeTurn;
  }

  /// Spends a turn's worth of energy.
  void spend() {
    assert(energy >= ACTION_COST);

    // Use mod instead of - to make multiple spends of the same turn idempotent.
    energy = energy % ACTION_COST;
  }
}