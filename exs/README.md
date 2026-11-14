# Examples

Games written in [Atmos][atmos] with the [pico](../) binding.

| Game | What it is | Run |
|------|------------|-----|
| [`birds/`](birds/) | A tutorial in 11 steps (`birds-01.atm` .. `birds-11.atm`): tasks, pools, collisions, pause. | `../../atmos-pico birds-11.atm` |
| [`rocks/`](rocks/) | A spaceship shooter for 2 simultaneous players. | `../../atmos-pico main.atm` |
| [`storm/`](storm/) | Clouds, rain, lightning and a car: a port of `ceu-sdl-storm`. | `../../atmos-pico main.atm` |

Each game is run from its own directory, since it loads its images and
sounds with relative paths:

```
cd birds/
ATMOS=/path/to/atmos ../../atmos-pico birds-11.atm
```

`ATMOS` is the compiler, built from <https://github.com/ia-atmos/lang>
(it may be omitted if `atmos` is in the `PATH`).
The SDL2 packages listed in the [main README](../README.md) are required.

A game does not include the binding nor opens the window: `atmos-pico`
makes the table `pico` available, and the program starts with the window
open.

# Running without a display

The loop of the binding has a test mode, driven by environment
variables (see the header of [`pico.atm`](../pico.atm)):

```
PICO_TESTS=1 SDL_AUDIODRIVER=dummy              \
PICO_ATM_FRAMES=200:33                          \
PICO_ATM_KEYS=100:dn:P,150:dn:P                 \
PICO_ATM_SHOT=120:/tmp/birds.png                \
xvfb-run -a ../../atmos-pico birds-11.atm
```

It runs 200 frames of 33ms each, presses `P` at frames 100 and 150, saves
the window at frame 120, and then quits.

[atmos]: https://github.com/ia-atmos/lang
