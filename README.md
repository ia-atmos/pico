# pico

<img src="c/res/logo.png" width="200" align="right">

A 2D graphics library for [Atmos][atmos], built on [pico-sdl](c/).

- `pico.atm` (to be written): the Atmos binding, at the repository root.
- [`c/`](c/): the C library (`pico-sdl`), with its tests and documentation.
- Games, still in the previous Atmos dialect and not yet ported to the
  binding:
    - [`exs/birds/`](exs/birds/): a tutorial in 11 steps
    - [`exs/rocks/`](exs/rocks/): a spaceship shooter for 2 players
    - [`exs/storm/`](exs/storm/): a port of `ceu-sdl-storm`

[atmos]: https://github.com/fsantanna/ceu-atmos

# C library

```
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libsdl2-gfx-dev
cd c/
./pico-sdl tst/cross.c
make tests
```

See [`c/README.md`](c/README.md).
