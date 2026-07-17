# Mesozoic Champions

A responsive Flutter demo of the single-player **Fossil Race** mode. The demo
runs on Android, web, and desktop targets and keeps mobile play in landscape.

## Demo loop

1. Select **Fossil Race** from the game menu.
2. Select **Fight** in the battle room.
3. Choose Rock, Paper, or Scissors. The rival's choice stays hidden.
4. Select **Showdown** to resolve damage and start the next turn.

Rock beats Scissors, Scissors beats Paper, and Paper beats Rock. On a draw,
both champions take half of the strongest attack. Health changes are animated.

The rival opens with a random move. It then changes its choice based on the
previous turn: after a draw it chooses one of its other moves, after a win it
repeats its move, and after a loss it counters the player's last move.

## Run

```sh
flutter pub get
flutter run -d chrome
```

Use `flutter devices` and replace `chrome` with an Android or desktop device to
run the same demo on another supported target.
