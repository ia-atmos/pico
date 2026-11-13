# The "Rocks!" game

A spaceship shooter game for 2 simultaneous players.

Built with [Atmos][atmos] and [pico][pico].

[atmos]: https://github.com/ia-atmos/lang
[pico]:  https://github.com/ia-atmos/env-pico

# Install

It requires the [Atmos][atmos] compiler and the development files of
SDL2:

```
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libsdl2-gfx-dev
```

# Run

```
ATMOS=/path/to/atmos ../../pico-atmos main.atm
```

# Instructions

- Hit the other ship.
- Avoid the rocks!
- Controls:
    - Left Ship: `WASD` to move, `Shift Left` to shoot.
    - Right Ship: Arrow keys to move, `Shift Right` to shoot.
