#!/bin/sh
# Runs the tests of the Atmos binding, headless.
#
#   tst/run.sh [name ...]
#
# With no names, runs every tst/*.atm, one at a time (some tests share
# output files). Requires `../atmos-pico` (see the Makefile at the root)
# and xvfb-run. Set ATMOS_ASAN=1 to run under the address sanitizer.

cd "$(dirname "$(realpath "$0")")" || exit 1

if [ ! -x ../atmos-pico ]; then
    echo "tst/run.sh : ../atmos-pico not found : run make ATMOS=/path/to/lang" >&2
    exit 1
fi

# the root of the repository, for `pico.check` (c/tst/out, c/tst/asr)
export PICO_ROOT="$(dirname "$PWD")"

# ATMOS_ASAN=1: ignores the leaks of the libraries under SDL
if [ -n "$ATMOS_ASAN" ] && [ -z "$LSAN_OPTIONS" ]; then
    export LSAN_OPTIONS="suppressions=$PWD/lsan.supp:print_suppressions=0"
fi

if [ $# -eq 0 ]; then
    set -- $(ls *.atm | sed 's/\.atm$//')
fi

mkdir -p ../c/tst/out
fail=0
for t in "$@"; do
    if PICO_TESTS=1 PICO_CHECK_INT= PICO_CHECK_ASR=1 SDL_AUDIODRIVER=dummy \
        xvfb-run -a ../atmos-pico "$t.atm" > "../c/tst/out/$t.log" 2>&1
    then
        echo "OK   $t"
    else
        echo "FAIL $t    (see c/tst/out/$t.log)"
        fail=1
    fi
done

if [ $fail -eq 0 ]; then
    echo "All tests passed!"
fi
exit $fail
