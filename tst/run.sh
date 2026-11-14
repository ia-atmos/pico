#!/bin/sh
# Runs the tests of the Atmos binding, headless.
#
#   ATMOS=/path/to/atmos tst/run.sh [name ...]
#
# With no names, runs every tst/*.atm, one at a time (some tests share
# output files). Requires xvfb-run. Set ATMOS_ASAN=1 to run under the
# address sanitizer.

cd "$(dirname "$(realpath "$0")")" || exit 1

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
