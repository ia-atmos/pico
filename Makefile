# Builds `atmos-pico`, the Atmos compiler dedicated to pico:
#
#   make ATMOS=/path/to/lang
#
# ATMOS is a checkout of https://github.com/ia-atmos/lang, already built
# (`make -C /path/to/lang`). The result is the executable `./atmos-pico`,
# which compiles and runs a program with `pico.atm` included and the C
# library linked:
#
#   cd exs/birds/ && ../../atmos-pico birds-11.atm
#
# It keeps depending on that checkout (the runtime), on a C compiler, and
# on the SDL2 development packages.

ATMOS ?= ../lang
PICO  := $(abspath .)
LIBS  := -lm -lSDL2 -lSDL2_ttf -lSDL2_image -lSDL2_mixer -lSDL2_gfx

.PHONY: all lib tests clean

all: atmos-pico

lib:
	$(MAKE) -C c lib

atmos-pico: lib pico.atm
	@test -x "$(ATMOS)/atmos" || \
	    { echo "make : compiler not found : $(ATMOS)/atmos (set ATMOS=/path/to/lang)"; exit 1; }
	$(MAKE) -C "$(abspath $(ATMOS))" env \
	    OUT="$(PICO)/atmos-pico" \
	    ENV="$(PICO)/pico.atm" \
	    ENV_CFLAGS="-I$(PICO)/c/src" \
	    ENV_LDFLAGS="$(PICO)/c/src/libpico-sdl.a $(LIBS)"

tests: atmos-pico
	tst/run.sh

clean:
	rm -f atmos-pico
	$(MAKE) -C c clean
