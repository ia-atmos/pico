# TODO

Everything that is pending: asked and not decided, reported and not
acknowledged, or known and not done. Keep it current: remove an item
when it is settled, add one whenever something is left open.

Last update: 2026-11-13 (after the second batch of binding changes).

## A. Decisions waiting for an answer

1. **Packaged binary.** `atmos -o` already gives a native executable with
   the runtime and `libpico-sdl.a` linked statically; SDL2 and its
   satellite libraries are dynamic. To decide: targets (Linux AppImage or
   static SDL; Windows exe + DLLs via mingw), and how resources (images,
   fonts, sounds) travel with the binary.
2. **Android / Termux.** Not tried. Plausible inside Termux with the
   `x11-repo` SDL2 packages and Termux:X11; not a native APK.
   `SDL2_gfx` availability unknown.
3. **Pinned values in table arguments** (`pin l = ..; f [up=l]` is
   `invalid escape`). Being discussed in the "Pin rules discussion"
   session. On our side the options are: keep resources in plain `val`s
   (today), or positional resource arguments (`pico.layer.empty(up,
   [dim=..])`, which accept pinned values).
4. **Event vocabulary across bindings.** Decided: unprefixed tags
   (signalled to the compiler session). Open: field names of key events
   (`key='A'` + `ctrl/shift/alt` here; `name=` in sdl; `key=262,
   name='RIGHT'` in ray) and the per-frame events (`:draw` only here;
   `:frame` and `:draw` in ray).
5. **Children of image / pixmap / screenshot layers.** Rejected today
   (C asserts at attach; Atmos raises an error). See
   `260710-image-pixmap-target-bug.md`.
6. **Binding functions as Atmos `func`s.** They are C `AFn`s because a
   native literal could not fail; the compiler now supports it
   (`st = a_error(..)`). Rewrite in the style of `lib/sdl.atm`, or keep.
7. **Tests of the games with `test { }` blocks.** Reported to the
   compiler session: needs `-t` through `atmos-pico`, and a way to
   script a run (frames, input, screenshots) from inside the program.
8. **Documentation site and releases of this repository.** The version
   branches were deleted here; `c/README.md` (badge, versions, Doxygen)
   still points to `fsantanna/pico-sdl`.
9. **First window options.** With the implicit open, a hidden or
   fullscreen window needs `pico.close()` + `pico.open [...]`, which
   shows a default window first. A way to give the options before the
   window exists (environment variable? a declaration read by the
   runner?) is not designed.
10. **File names in error messages** are absolute (the wrapper that
    injects the include lives in a temporary directory). Short names
    would need the wrapper written next to the program.
11. **Storm: drops stretch from their top-left corner** (kept for an
    identical picture after the move to centre anchors). Stretching
    around the centre is simpler code and shifts drops by up to 3px.
12. **Storm: the car has no screen limit** (holding Left/Right drives it
    off screen for good). As in the port.
13. **`'%'` crops surviving a resize.** Resizing a layer with live
    sub-layers is rejected for every crop mode. An exception for `'%'`
    crops (sub-layers reading through their source) was discussed and
    not taken.

## B. Work that is known and not done

1. **Window close in imperative programs.** With aids on and expert off,
   the C library calls `pico_close(); exit(0)` from inside
   `pico_input_event` (`c/src/input.c`), so an Atmos program blocked
   there ends without running its `defer` blocks. Needs a way to disable
   that exit alone. The reactive loop is not affected.
2. **CI for Atmos**: the workflow builds `ia-atmos/lang` and runs
   `tst/run.sh`. Actions were enabled on 2026-11-13; the first run is to
   be checked.
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
11. **A freed or cleared child stays visible** in its parent's texture
    until the parent is cleared (children are composited into the
    parent; outside expert mode every clear presents).
14. **Window resize with a live sub-layer of the window**: a real resize
    event (or a fullscreen toggle) resizes the window layer inside
    `pico_input_event` and now hits the C assert "cannot resize a layer
    with live sub-layers"; the binding cannot turn that into an error.
15. **`pico.atm` prelude formatting**: after the rename to
    `_pico_atmos_`, 155 lines are over 80 columns and the macro
    backslashes are misaligned.
16. **Programs cannot run code before the window exists** (implicit
    open): a `setenv` in the program for a variable read at `pico_open`
    is too late.
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
2. **`pico.set.scene [dim=..]` with live sub-layers is an error even
   when the size does not change** (the C code replaces the texture
   anyway).
3. **`'default'` can never be a font path** (`font=:default` is that
   string; use `'./default'`); `pico.get.pencil().font` is `nil` for the
   built-in font.
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
    per frame, with a grid in plain Atmos filtering near pairs; a drop
    may travel up to one frame further before reacting. Boom pushes stay
    per clock piece.
11. **`PICO_ROOT`** is exported by `atmos-pico`; `$name` inside a
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
