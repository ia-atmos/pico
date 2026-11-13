# TODO

Everything that is pending: asked and not decided, reported and not
acknowledged, or known and not done. Keep it current: remove an item
when it is settled, add one whenever something is left open.

Last update: 2026-11-13.

## A. Decisions waiting for an answer

1. **`:world` / `:window` as tags.** Accept the tags wherever a layer is
   expected, instead of (or besides) `pico.layer.world()` /
   `pico.layer.window()`. Tags are strings at runtime, and a layer
   argument is told from a mode string (`'!'`, `'%'`, `'#'`) by content,
   so it is feasible. Suggested: accept both.
2. **`c/tst/expert.c` timing.** `assert(dt>=100 && dt<=105)` after
   `pico_input_delay(100)` failed twice under 4 parallel valgrind runs
   and passes alone. Widen the upper bound (110?), or widen it only under
   `PICO_TESTS`, or leave it. The observed failing `dt` was not recorded.
3. **`pico_set_scene_dim` / `pico_set_scene` on a layer with live
   sub-layers.** They replace the texture; the sub-layers keep the old
   (destroyed) one. Options: (a) sub-layers read the texture and
   dimensions through their source at draw time (suggested; the sub
   already stores its source); (b) assert that the layer has no
   sub-layers.
4. **Event tags across bindings.** `pico.atm` emits unprefixed tags
   (`:quit`, `:key.dn`, `:mouse.button.dn`, `:draw`), as the old
   `env-pico`; `lib/sdl.atm` and `raylib.atm` prefix them (`:sdl.key.dn`,
   `:rl.key.dn`, `:rl.frame`, `:rl.draw`). One convention for all
   bindings is needed: a shared unprefixed vocabulary (programs move
   between bindings; only one environment exists per program), or a
   prefix per library. Field names differ too (`key='A'` here,
   `name='A'` in sdl, `key=262, name='RIGHT'` in raylib).
5. **Implicit include/open/close.** `pico-atmos` could generate the
   `include`, and `main` could open pico before the program runs
   (`pico.close` is already implicit). Cost: `pico.open [..]` arguments
   (hidden window, fullscreen) and the open/close tests need an explicit
   mode.
6. **Packaged binary.** `atmos -o` already gives a native executable with
   the runtime and `libpico-sdl.a` linked statically; SDL2 and its
   satellite libraries are dynamic. To decide: targets (Linux AppImage or
   static SDL; Windows exe + DLLs via mingw), and how resources (images,
   fonts, sounds) travel with the binary.
7. **Android / Termux.** Not tried. Plausible inside Termux with the
   `x11-repo` SDL2 packages and Termux:X11 (it is a Linux userland with
   clang); not a native APK. `SDL2_gfx` availability unknown.
8. **`font=false`** selects the built-in font in `pico.set.pencil`
   (as in the Lua binding; `nil` cannot be told from an omitted field).
   Alternatives: a tag such as `:default`.
9. **`tst/move.atm`** calls C's `rand()` in a native literal, because
   the reference images come from the C test and `math.random` gives
   another sequence. Alternative: a faithful port that fails, or new
   reference images for the Atmos test.
10. **Guide 5.1.** `tst/guide.atm` redraws the image before the zoom and
    `doc/guide.md` does not; three screenshots differ on a few
    anti-aliased pixels. Add the line to the guide, or drop it from the
    test.
11. **Storm, three judgement calls** made in the port, after the Céu
    original: `anchor='NW'` on the physics rects; cloud/collision timers
    in seconds; the fix of the empty random interval. To confirm.
12. **Storm with the default (centre) anchor** instead of `anchor='NW'`:
    positions would become centres and the `pst + len/2` arithmetic goes
    away.
13. **Per-frame clear in the reactive loop** applies to the current
    layer, not necessarily the world (as in the old `env-pico`).
    Confirmed: if a program awaits with another layer current, only that
    layer is cleared and everything drawn on the world accumulates; a
    child without `clear=true` accumulates even when the world is
    current. Options: (a) keep and document; (b) always clear the world
    (cascades to `clear=true` descendants; suggested); (c) clear the
    world and the current layer; (d) reset the current layer to the
    world at each frame.
14. **Children of image / pixmap / screenshot layers.** Rejected today
    (C asserts at attach; Atmos raises an error). See
    `260710-image-pixmap-target-bug.md`.
15. **Binding functions as Atmos `func`s.** They are C `AFn`s because a
    native literal could not fail; the compiler now supports it
    (`st = a_error(..)`). Rewrite in the style of `lib/sdl.atm`, or keep.
    The `PA_`/`pa_` prefixes are no longer required either.
16. **Tests of the games** with `test { }` blocks (`atmos -t`): a game
    could carry its own scripted run and assertions. Needs `pico-atmos`
    to pass `-t`, and scripted input from inside the program.
17. **Version branches** (`v0.1`..`v0.7`) were deleted from this fork;
    the links in `c/README.md` (badge, versions, Doxygen) still point to
    `fsantanna/pico-sdl`. Decide where the documentation site and the
    releases of this repository live.

18. **`pico.input.event` rejects more than 2 arguments**, stricter than
    the other functions, which ignore extras. Keep, or relax.
19. **Remote of the working checkout** still points at the old address
    `ia-atmos/pico` (it redirects to `ia-atmos/env-pico`); repointing
    was blocked by the session's permission check and awaits the user.

## B. Work that is known and not done

1. **Window close in imperative programs.** With aids on and expert off,
   the C library calls `pico_close(); exit(0)` from inside
   `pico_input_event` (`c/src/input.c`), so an Atmos program blocked
   there ends without running its `defer` blocks. Needs a way to disable
   that exit alone. The reactive loop is not affected.
2. **CI for Atmos**: the workflow builds `ia-atmos/lang` and runs
   `tst/run.sh`, but no "Tests" run has ever started in this repository:
   Actions on a fork stay disabled until enabled in the Actions tab.
   First run to be checked once enabled.
3. **Binding: smaller defects noticed and not fixed**:
   - `PICO_ATM_KEYS`: malformed entries and unknown key names are
     ignored or emitted as they are; modifiers cannot be scripted; the
     `PICO_ATM_SHOT` path is not checked;
   - `PICO_ATM_MOUSE`: left button only; a `dn`/`up` emits no motion;
   - `pico.open`: `fs=`/`show=` accept any value by truthiness; a
     non-string `title=` reports `bad argument #1` although it is a field;
   - a multi-character mode string is accepted by its first character;
   - `pico.output.screenshot(layer, rect, x)` ignores the third argument;
   - `pico.layer.images` grid: fractional `w`/`h` truncated, `n<1` ignored;
   - `pico.input.delay` truncates fractional ms and accepts negatives;
   - `pico.check` creates only the last directory level (`out`).
4. **C library: real mouse events read position and buttons from
   `SDL_GetMouseState` at conversion time**, not from the event: a
   queued quick click can arrive as `:mouse.button.dn` with `left=false`,
   and queued motions all report the latest position.
5. **`c/tst/todo/*.c`** only had `pico_init` renamed; they do not build.
6. **Reference images with no test**: `c/tst/asr/push-*.png` (the
   push/pop test is gone).
7. **C library: a freed `Pico_Font*` still referenced by a pencil** is
   undefined behaviour and is not detected (the Atmos binding prevents
   it; C programs are on their own).
8. **C library: the text cache is unbounded** until `pico_close` (as
   decided); a changing string drawn with `pico_output_draw_text` grows
   memory.
9. **C library: no queries** for "is pico open", "has children", "has
   live sub-layers"; the Atmos binding tracks them itself and cannot
   notice a close it did not make.
10. **C library: argument errors are `assert`s** (bad Y4M header,
    `IMG_SavePNG` into a missing directory, invalid dim/tile modes, ...).
    The binding pre-checks the ones it can see.
11. **A freed child stays visible** in its parent's texture until the
    parent is cleared (children are composited into the parent).
12. **`.claude/plans/`** still describes realms, keys and push/pop
    (historical; nothing was updated).
13. **Release**: `HISTORY.md` has the `v0.8` entry open; version strings
    (`pico-sdl --version` prints `v0.7`).

## C. Reported and not acknowledged

Changes made on judgement during the port, reported once, with no answer.

1. **A layer lives as long as its value is referenced** (Atmos): an
   attached child whose value is dropped is freed and disappears; a
   parent, a sub-layer source, the current layer and a pencil's font are
   kept alive by what depends on them.
2. **Programs call `pico.open()` explicitly** (the old environment
   opened pico on `require`).
3. **Explicit `pico.layer.free` / `pico.font.free` / `pico.sound.free`
   of something in use raises an error.**
4. **`pico.xin.*` is `pico.in.*`**; `pico.get.expert()` was added.
5. **`pico.get.video(layer)` / `pico_get_video_path`** naming.
6. **Tests changed in form**:
   - `c/tst/layers.c`: three key-reuse sections removed;
   - `c/tst/get-set.c`: loads `res/tiny.ttf` (it stored an unloaded
     path string before);
   - `c/tst/stack.c` -> `free.c`, `push-pop-recycle.c` -> `free-recycle.c`,
     `text-dyn.c` -> `text-cache.c`, `unique.c` deleted; new `close.c`,
     `quit-aid.c`;
   - `tst/sheet.atm`: asserts count/type of the returned layers, not key
     names; `tst/guide.atm` 7.5 has no push/pop.
7. **`tst/lsan.supp`** suppresses the SDL start-up leak (libdbus) under
   `ATMOS_ASAN`, as `c/valgrind.supp` does for valgrind.
8. **Storm README** was written from scratch (it was only a title).
9. **Language rule met by the binding** (on the compiler author's list):
   a temporary table argument cannot hold a pinned value
   (`pin l = ..; f [up=l]`).
10. **Storm rework**: drop-vs-drop and drop-vs-car collisions run once
    per frame, with a native C filter of near pairs inside `ts.atm`; a
    drop may travel up to one frame further before reacting. Boom pushes
    stay per clock piece.
11. **`PICO_ROOT`** is exported by `pico-atmos`; `$name` inside a
    `:prelude` block is Atmos interpolation, even in a C comment.
12. **Runtime behaviour to keep in mind**: `loop us on :clock` wakes at
    every piece of time (one per pending timer instant), not once per
    frame; per-frame logic goes on `:draw`.

## D. Older items (before the Atmos port; to review)

Written for the Lua binding. Obsolete at first sight: 5 (realms), 9
(pico-lua), 10 (done), 15 (done).

1. Support `'transparent'` as color string
    - `PICO_COLOR_TRANSPARENT` is `Pico_Color_A` (4 bytes)
    - `c_color_s` casting to `Pico_Color*` reads only `{0,0,0}`
    - Needs RGBA consumer — `set.color.draw` and `set.color.clear` use RGB only

2. Guide: use input `dt` in animations
    - Animation examples should use `dt` from `pico.input.event`
    - Currently uses fixed increments

3. Guide: `pico.get.now` never introduced
    - Used in section 9.2 but never formally introduced

4. Support percentage mode for alpha
    - `pico.set.alpha('%', 0.5)` — normalized 0.0–1.0
    - Currently only raw 0–255

5. Document realm hash table / resource management
    - The realm hash table (Lua-side resource registry) is undocumented
    - Unclear how resources are managed / when they are released
    - Document in HISTORY.md
    - Document in `lua/doc/guide.md`

6. Group all drawing state under `pico.set.draw.*`
    - Move color, style, alpha, font under `pico.set.draw`
    - Consider `pico.draw { ... }` block with auto push/pop

7. Review and complete guide
    - [#103](https://github.com/fsantanna/pico-sdl/issues/103)

8. `pico.set` vs multi-arg setters
    - `set` dispatch calls `field(v)` with single argument
    - Multi-arg setters (`expert`, `video`) lose extra arguments
    - See `.claude/plans/set.md`
    - [#102](https://github.com/fsantanna/pico-sdl/issues/102)

9. README pico-lua cross image
    - [#101](https://github.com/fsantanna/pico-sdl/issues/101)

10. Support screenshots of layers
    - [#98](https://github.com/fsantanna/pico-sdl/issues/98)

11. Non-blocking video I/O
    - See `.claude/plans/select.md`
    - [#93](https://github.com/fsantanna/pico-sdl/issues/93)

12. Help aid
    - [#72](https://github.com/fsantanna/pico-sdl/issues/72)

13. Expert mode should disable all aids
    - [#71](https://github.com/fsantanna/pico-sdl/issues/71)

14. Fullscreen vs accelerated rendering
    - Redraw does not work in fullscreen + accelerated
    - Send example `bug.c` to SDL mailing list
    - [#65](https://github.com/fsantanna/pico-sdl/issues/65)

15. Create a logo for the project
    - [#46](https://github.com/fsantanna/pico-sdl/issues/46)

16. ThorVG integration
    - Replace SDL2_gfx (and later SDL2_ttf) with ThorVG
    - SwCanvas renders to ARGB8888, uploaded to SDL_Texture
    - Adds SVG, anti-aliasing, gradients, bezier, stroke, transforms
    - Phase 2: thickness / stroke width for drawing primitives
      ([#62](https://github.com/fsantanna/pico-sdl/issues/62))
    - See `.claude/plans/thorvg.md` (4 phases)

17. Networking support (`pico-sdl-net`)
    - SDL3 needed due to blocking calls in SDL2_net

18. Layout system
    - Dispatch mechanism
    - Click handling

19. Default DejaVu font
    - Consider replacing Tiny font
      (WIP on branch `2026-04-font-pixel-operator` — see
      `.claude/plans/2026-04-pixel-operator.md` on that branch)
    - Decide default font size
    - Predefined font options (tiny, dejavu, etc)
    - Test other fonts (done — see `done/2026-04-dejavu-font.md`)

21. `pico_get_image/text` should accept ref parameter
    - See `lua/tst/image_pct` commented tests

23. Layer scene graph (up-layer)
    - **BLOCKER**: realm frees keys on remove
      (`src/realm.hc:74`), so borrowed id pointers in
      `up`/`dn`/`nxt` dangle — `realm_get` would `memcmp`
      freed memory.
      Need id interning, refcount, arena, or eager detach.
      See `.claude/plans/up-layer.md` §10.
    - Explicit `up` (parent) id at create; realm-as-sole-owner
    - Auto-composite traversal in `pico_output_present`
    - Free-mode `output.draw.layer` for detached layers only
    - String-keyed `pico.mouse.get/set(layer)` and `pico.vs(l1, l2)`
    - Post-composite clear with per-type `view.keep` defaults
    - Closes #22 (`'w'` vs `r` divergence)
    - Depends on `sub-layer-parent.md` (eliminates `Pico_Layer.parent`)
    - See `.claude/plans/up-layer.md`, `.claude/plans/sub-layer-parent.md`

24. Consider splitting `pico_set_view` into separate setters
    - Currently an all-in-one with 9 optional params
    - Alternatives: `pico_set_alpha`, `pico_set_target`, etc.
    - See item 6 (`pico.set.draw.*` group)

25. `pico.layer.text` dim: implement `w`-given combinations
    - Contract: all `dim` w/h combinations valid, except `w=h=0`
      (permanent error); missing ones raise "not implemented"
    - Implement in C (`pico_layer_text_mode`, layer.c) — the dim
      resolve already lives there; Lua binding passes `dim` through
    - `w!=0, h=0` (optimal-h): probe render at reference height,
      `h = w * h_probe / w_probe`, re-render (approximate `w`;
      fonts are not linear across sizes)
    - `w!=0, h!=0` (forced box): render at `h`, occupy exactly
      `w` — needs a bake/resample step (or compose with target)
    - Consider symmetric support in `pico.get.text`
      (currently asserts `h!=0`)

26. `lua/Makefile`: `../src/libpico-sdl.a` has no source deps
    - Editing `src/*.c` then running only `cd lua && make tests`
      links `pico_native.so` against a stale `.a` (silent ABI
      mismatch when signatures change; bit during layer-create work)
    - Add prerequisite on `../src/*.c ../src/*.h` (or always
      recurse)

22. `'w'` vs `r`-relative divergence near edges
    - `pico_output_draw_pixel({'w', ...})` snaps through screen log grid
      (5 win px / log px) while collision via `up = &r` is continuous
    - Near edges of a distorted `r`, render and collision disagree
    - Repro: `tst/mouse-w-click.c` (mouse `'w' (400, 382)`)
    - See `.claude/plans/w-bug.md` open follow-ups for fix options
