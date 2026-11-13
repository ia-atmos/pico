# pico-storm

A port of [ceu-sdl-storm][storm] to [Atmos][atmos] and [pico][pico].

[storm]: https://github.com/fsantanna/ceu-sdl-storm
[atmos]: https://github.com/ia-atmos/lang
[pico]:  https://github.com/ia-atmos/pico

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

- `Left` and `Right` move the car.
- `Down` spawns a lightning.
