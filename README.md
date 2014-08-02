This is the repo for the demos in [this article][] on writing a turn-based game
loop for a roguelike.

## Running them yourself

The code here is written in Dart. To get it up and running locally, you'll need
to have the [Dart SDK][sdk] installed.

Once you have Dart installed and its `bin/` directory on your `PATH`, then:
 
1. Clone this repo.
2. From the root directory of it, run: `$ pub serve`
3. In your browser, open: `http://localhost:8080`

Pub will automatically compile the Dart code to JavaScript if you hit that URL
with a production browser. Leave pub serve running, and whenever you change the
Dart code, it will notice that and recompile the JS on the fly.

You can also run the Dart code natively using [Dartium][], which comes with the
Dart SDK. Just hit the same URL and it is smart enough to serve the raw Dart
code instead of the compiled JS.

[this article]: http://journal.stuffwithstuff.com/2014/07/15/a-turn-based-game-loop/
[dart]: http://dartlang.org
[sdk]: https://www.dartlang.org/tools/download.html
[dartium]: https://www.dartlang.org/tools/dartium/
