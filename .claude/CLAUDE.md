# CLAUDE.md

- The repository root is the Atmos binding; the C library lives in `c/`.
- In `c/valgrind.supp`, last clause `sdl-init`, line `src:pico.c:N`.
    - `src:pico.c:N` points to file `c/src/pico.c` at line `N`
    - `N` is the line in `pico_open` that calls `SDL_Init`
    - **update `N` whenever `c/src/pico.c` changes**

## Build & Run

### C Programs

Compile and run a C program (from `c/`):

```bash
cd c/
./pico-sdl path/to/program.c
```

Manual compilation:

```bash
gcc /path/to/program.c -I c/src -L c/src -lpico-sdl \
    -lm -lSDL2 -lSDL2_ttf -lSDL2_image -lSDL2_mixer -lSDL2_gfx
```

### Atmos Programs

The binding is `pico.atm`; the compiler is https://github.com/ia-atmos/lang.

`atmos-pico` is the compiler dedicated to pico, built by the root `Makefile`
from a checkout of the compiler (it is not versioned):

```bash
make ATMOS=/path/to/lang                # builds ./atmos-pico
cd dir/of/program && /path/to/atmos-pico program.atm
```

## Tests

### Running

```bash
cd c/ && make tests                     # C library
tst/run.sh [name]                       # Atmos binding (tst/*.atm)
```

### Visual Regression

Visual tests use `check.h` to compare rendered output against expected images.

```bash
cd c/
make int  T=<app>   # inspect
make gen  T=<app>   # generate asr/
make test T=<app>   # check
```
