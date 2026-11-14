# pico-storm

A port of [ceu-sdl-storm][storm] to [Atmos][atmos] and [pico][pico].

[storm]: https://github.com/fsantanna/ceu-sdl-storm
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
../../atmos-pico main.atm
```

# Instructions

- `Left` and `Right` move the car.
- `Down` spawns a lightning.

# Notes

- The game is all in Atmos, with no C of its own.
- The position of an object is its center, which is the default anchor
  of pico.
- The collisions between drops and between drops and the car are tested
  once per frame.
  The drops go into a grid (`GRID` in `ts.atm`), and each drop is only
  compared with those in the cells around it: first as plain numbers,
  and then with `pico.vs.rect.rect` if they are close.
