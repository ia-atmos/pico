# API: pico-atmos

The binding is the file [`pico.atm`](../pico.atm).
A program includes it with a path relative to the program itself, and runs
with the script [`pico-atmos`](../pico-atmos), which requires the
[Atmos](https://github.com/ia-atmos/lang) compiler (`atmos` in the `PATH`, or
as set in the environment variable `ATMOS`):

```
include "../pico.atm"
pico.open()
...
```

```
$ pico-atmos file.atm
```

Everything lives in the single table `pico`.
All operations, except `pico.open`, `pico.color.*`, and `pico.equal`, raise the
error `pico is not open` if called before `pico.open` or after `pico.close`.

- [Types](#types)
- [Lifetimes](#lifetimes)
- [Operations](#operations)
- [Reactive Mode](#reactive-mode)
- [Tests](#tests)

## Types

In alphabetical order:

- **Anchor**: `string` | `[ x: number, y: number ]`
    - String: `'C'`, `'NW'`, `'N'`, `'NE'`, `'E'`, `'SE'`, `'S'`, `'SW'`, `'W'`
    - an absent anchor is `'C'` (center)
    - the anchors that operations return are always tables (`'C'` is
      `[x=0.5, y=0.5]`)
- **Color**: `table` | `integer` | `string`
    - Table: `[ ['!'|'%'], r: number, g: number, b: number [, a: number] ]`
        - `'!'` (default): components from `0` to `255`
        - `'%'`: components from `0.0` to `1.0`
        - an absent `a` is opaque
    - Integer: `0xRRGGBB` (24-bit, alpha=0xFF) or `0xRRGGBBAA` (32-bit)
    - String:
        `'black'`, `'white'`, `'gray'`, `'silver'`, `'red'`, `'green'`,
        `'blue'`, `'yellow'`, `'cyan'`, `'magenta'`, `'orange'`, `'purple'`,
        `'pink'`, `'brown'`, `'lime'`, `'teal'`, `'navy'`, `'maroon'`,
        `'olive'`, `'transparent'`
    - the colors that operations return are always tables
      `[ r: integer, g: integer, b: integer, a: integer ]` (from `0` to `255`)
- **Dim**: `[ '!'|'%'|'#', [w: number], [h: number] ]`
    - missing `w` or `h` is infered from source
- **Event**: a table tagged with the type of the event (`e.tag`)
    - `:quit []`
    - `:window.resize [ w: integer, h: integer ]`
    - `:key.dn [ key: string, ctrl: boolean, shift: boolean, alt: boolean ]`
    - `:key.up [ ... ]`
    - `:mouse.motion [ '!', x: number, y: number, anchor: Anchor,
        left: boolean, right: boolean, middle: boolean ]`
    - `:mouse.button.dn [ ... ]`
    - `:mouse.button.up [ ... ]`
    - the tag is a string, as in `e.tag == 'key.dn'`, which is also testable
      with the operator `??`, as in `e ?? :key.dn` or `e ?? :mouse`
    - `key` is the name of the key, such as `'A'`, `'Escape'`, `'Up'`, or
      `'Left'`
    - the mouse position of an event is in pixels of the window
- **Flip**: `'none'` | `'horizontal'` | `'vertical'` | `'both'`
- **Font**: a native value, as loaded by `pico.font.load`
- **Layer**: a native value, as created by the `pico.layer.*` constructors
- **Mouse**: `[ '!'|'%'|'#', x: number, y: number, anchor: Anchor, left: boolean, right: boolean, middle: boolean ]`
- **Pos**: `[ '!'|'%'|'#', x: number, y: number [, anchor: Anchor] ]`
- **Rect**: `[ '!'|'%'|'#', x: number, y: number, [w: number], [h: number] [, anchor: Anchor] ]`
    - missing `w` or `h` is infered from source
- **Rotation**: `[ angle: integer [, anchor: Anchor] ]`
- **Sound**: a native value, as loaded by `pico.sound.load`
- **Tile**: `[ '!'|'#'|'%', w: integer, h: integer ]`
- **Video**: `[ dim: Dim, fps: integer, frame: integer, done: boolean ]`

In a `Dim`, `Pos`, `Rect`, `Mouse`, and `Tile`, the **mode** is the string at
index `0` of the table, and is mandatory:

- `'!'`: pixels
- `'%'`: percentage of the layer
- `'#'`: tiles

The values that operations return are not symmetric with the ones they accept:
an `Anchor` always comes back as a table `[x=, y=]`, never as a string, and a
`Color` always comes back as `[r=, g=, b=, a=]`, with integers from `0` to
`255` and no mode at index `0`.
Both are valid as arguments.

## Lifetimes

Layers, fonts, and sounds are native values:

```
val l = pico.layer.empty [ dim=['!', w=32, h=32] ]
val f = pico.font.load("x.ttf")
val s = pico.sound.load("x.wav")
```

- A resource lives as long as its value is referenced.
  It is released
    with its last reference,
    with the block of its `pin`, or
    with `pico.layer.free(l)`, `pico.font.free(f)`, `pico.sound.free(s)`.
- A layer attached to a parent (`up`) must be kept somewhere: if its value is
  dropped, the layer is freed and disappears from the screen.
- What a resource depends on outlives it:
    the parent of a layer (`up`),
    the source of a sub-layer (`sup`),
    the current layer (`pico.set.layer`), and
    the font of a pencil.
  If such a value is dropped, or pinned in a block that ends first, its release
  is postponed until nothing depends on it.
  In this case, `pico.get.layer()` and `pico.get.pencil().font` evaluate to
  `nil` if the value is gone.
- The explicit `free` of a resource in use raises an error.
  After a `free`, any use of the value raises an error.
- A plain `val` is enough to hold a resource.
  A resource in a `pin` cannot go into a table argument (`[up=l]`), unless the
  table is also pinned, as for any pinned value:

    ```
    pin l = pico.layer.empty [...]
    pin t = [ up=l, dim=... ]
    val x = pico.layer.empty(t)
    ```

- `pico.close()` releases all resources: every value from before it is invalid
  afterwards, even after a new `pico.open()`, and any use raises an error.
- `pico.layer.world()` and `pico.layer.window()` evaluate to the two root
  layers, always as the same shared values, which cannot be pinned or freed.
- The resources that operations load from a path or content
  (`pico.output.draw.image`, `pico.output.draw.text`, `pico.output.draw.video`,
  `pico.output.sound(path)`, and `pico.set.pencil [font=path]`) are loaded
  once and kept until `pico.close()`.

## Operations

In alphabetical order:

- **pico.check**, **pico.equal**: see [Tests](#tests).
- **pico.close**: Finalizes pico, and invalidates all layers, fonts, and
  sounds.
    - `pico.close ()`
    - A program that terminates with pico open closes it automatically.
- **pico.color**
    - **pico.color.alpha**: Returns a copy of the color with alpha set.
        - `pico.color.alpha (clr: Color, a: integer) -> Color`
    - **pico.color.darker**: Makes a color darker.
        - `pico.color.darker (clr: Color, pct: number) -> Color`
    - **pico.color.lighter**: Makes a color lighter.
        - `pico.color.lighter (clr: Color, pct: number) -> Color`
    - **pico.color.mix**: Mixes two colors.
        - `pico.color.mix (c1: Color, c2: Color) -> Color`
- **pico.cv**
    - Projects a value from `L_fr`'s frame into `L_to`'s frame via
      the parent chain. Either layer may be `nil` (== cur). Each
      layer must be cur, an ancestor, or a descendant of cur;
      siblings project via cur in two steps.
    - `to` accepts two forms:
        - **table**: filled in-place (mode/anchor read from input);
          returns the same table.
        - **mode string** (`'!'`, `'%'`, `'#'`): builds and returns
          a fresh value; anchor defaults to `'C'` (center; Pos/Rect only).
    - Args are matched left-to-right against the 4-slot template
      `(L_to, to_or_mode, L_fr, fr)`. Both explicit `nil`s and
      trailing/leading omissions are accepted; a mismatched type
      leaves the slot empty without consuming the arg, so short
      forms like `(to, fr)`, `(L_to, to, fr)`, `(L_to, mode, fr)`
      are all valid. `to_or_mode` and `fr` are required.
    - **pico.cv.pos**: Projects a Pos.
        - `pico.cv.pos (L_to: Layer?, to: Pos, L_fr: Layer?, fr: Pos) -> Pos`
        - `pico.cv.pos (L_to: Layer?, mode: string, L_fr: Layer?, fr: Pos) -> Pos`
    - **pico.cv.rect**: Projects a Rect.
        - `pico.cv.rect (L_to: Layer?, to: Rect, L_fr: Layer?, fr: Rect) -> Rect`
        - `pico.cv.rect (L_to: Layer?, mode: string, L_fr: Layer?, fr: Rect) -> Rect`
    - **pico.cv.dim**: Projects a Dim (no position component).
        - `pico.cv.dim (L_to: Layer?, to: Dim, L_fr: Layer?, fr: Dim) -> Dim`
        - `pico.cv.dim (L_to: Layer?, mode: string, L_fr: Layer?, fr: Dim) -> Dim`
- **pico.font**
    - **pico.font.load**: Loads a font from a TTF file.
        - `pico.font.load (path: string) -> Font`
        - The font is selected with `pico.set.pencil [font=f]`.
    - **pico.font.free**: Releases a font.
        - `pico.font.free (font: Font)`
        - It is an error to free a font in use by a pencil.
- **pico.get**: Getters for various properties and settings.
    - **pico.get.aids**: Gets the state of the automatic aids (see
      `pico.set.aids`).
        - `pico.get.aids () -> boolean`
    - **pico.get.effect**: Gets effect configuration.
        - `pico.get.effect () -> [ alpha: integer, color: Color, flip: Flip, grid: boolean, rotate: Rotation ]`
    - **pico.get.expert**: Gets the state of the expert mode.
        - `pico.get.expert () -> boolean, integer`
        - Returns if the expert mode is on, and its FPS:
          `0` = wait forever, `-1` = as fast as possible, `N>0` = fixed FPS.
    - **pico.get.image**: Gets image dimensions.
        - `pico.get.image (path: string) -> Dim`
        - `pico.get.image (mode: string, path: string) -> Dim`
        - `pico.get.image (dim: Dim, path: string) -> Dim`
        - `pico.get.image (dim: nil, path: string) -> Dim`
        - `mode`: `'!'` pixels, `'%'` percentage, `'#'` tiles
        - String-mode and nil/no-arg forms build a fresh
          `[mode, w=0, h=0]` table; default mode is `'!'`.
        - Table form is mutated in place; missing `w`/`h` (zero)
          axes are filled from the image's natural pixel size,
          aspect-preserving.
        - Returns the rel `Dim` (the same table when one was
          passed, or the freshly built one).
        - Forms:
            - `pico.get.image('cat.png')` — pixels
            - `pico.get.image('%', 'cat.png')` — percent
            - `pico.get.image(['%', w=0.5], 'cat.png')` — fills `h`
    - **pico.get.keyboard**: Gets keyboard modifier state.
        - `pico.get.keyboard () ->
          [ key: string, ctrl: boolean, shift: boolean, alt: boolean ]`
        - `key` is always the empty string: the call polls the modifiers
          only, and the key itself only comes in the events `:key.dn` and
          `:key.up`.
    - **pico.get.layer**: Gets the current layer.
        - `pico.get.layer () -> Layer?`
        - Returns `nil` if the value of the current layer is gone (see
          [Lifetimes](#lifetimes)).
    - **pico.get.mouse**: Gets mouse position and button state in
      `layer`'s frame. `layer` defaults to cur when omitted or `nil`.
        - `pico.get.mouse ([layer: Layer?,] mode: string) -> Mouse`
        - `pico.get.mouse ([layer: Layer?,] pos: Pos) -> Mouse`
        - `mode`: `'!'` pixels, `'%'` percentage, `'#'` tiles
        - String-mode form defaults `anchor` to `C` (cell-center).
          Use the table form with an explicit `anchor` field to override
          (e.g. `'NW'`); only the mode and the anchor of the table are read.
        - Returned `Mouse` is a new table, which mirrors `mode` and `anchor`
          of the request.
        - After an entry of `PICO_ATM_MOUSE` (see [Tests](#tests)), the
          position and the left button are the scripted ones.
        - Forms:
            - `pico.get.mouse('!')` — cur, pixels, C anchor
            - `pico.get.mouse(nil, '!')` — explicit nil = cur
            - `pico.get.mouse(pico.layer.world(), '%')` — given layer's frame
            - `pico.get.mouse(['!', anchor='NW'])` — explicit anchor
    - **pico.get.now**: Gets milliseconds since initialization.
        - `pico.get.now () -> integer`
    - **pico.get.pencil**: Gets pencil configuration.
        - `pico.get.pencil () -> [ color: Color, font: (Font|string)?, style: 'fill'|'stroke' ]`
        - `font` is as set: a `Font`, a path, or `nil` for the built-in font
          (and for a `Font` whose value is gone).
    - **pico.get.scene**: Gets scene configuration.
        - `pico.get.scene () -> [ dim: Dim, tile: Tile, target: Rect, source: Rect, clip: Rect, clear: boolean ]`
        - `dim` and `tile` are always in pixels (`'!'`).
    - **pico.get.text**: Gets text dimensions.
        - `pico.get.text (dim: Dim, text: string) -> Dim`
        - `dim` is **required** and must be a table: `h` is the
          input font size (in `dim.mode`'s realm).
        - `w` is filled in by the call (when initially `0`).
        - Returns the rel `Dim` (the same table passed in,
          mutated). To get pixels, use `'!'` mode or multiply
          by the scene dim.
        - No string-mode shorthand: `h` cannot be conveyed.
        - `text` may also be a number.
    - **pico.get.video**: Gets video information.
        - `pico.get.video (video: Layer|string) -> Video`
        - `pico.get.video (mode: string, video: Layer|string) -> Video`
        - `pico.get.video (rect: Rect, video: Layer|string) -> Video`
        - `pico.get.video (rect: nil, video: Layer|string) -> Video`
        - `video`: a layer created by `pico.layer.video`, or the path of a
          video file. With a layer, the arguments may also be given as
          `(video, rect|mode)`.
        - `mode`: `'!'` pixels, `'%'` percentage, `'#'` tiles
        - Returns the full `Video` (`[dim, fps, frame, done]`).
        - `Video.dim` **is** the slot-1 input table: caller's
          `Rect` (table-form, mutated in place) or a freshly
          built rect (string-form / nil / no-arg). Only
          `mode`/`w`/`h` are meaningful for dim use; `x`/`y`
          may be present (zero by default).
    - **pico.get.window**: Gets window configuration.
        - `pico.get.window () -> [ fullscreen: boolean, show: boolean, title: string ]`
- **pico.in**
    - Composes a child value (`in`) onto a parent rect (`out`) and
      returns a flat value (no parent reference) that resolves to
      the same absolute coordinates. Mode and anchor of `in` are
      preserved; numeric `x`/`y`/`w`/`h` are re-expressed within
      the current scene.
    - **pico.in.rect**: Composes a child rect onto a parent rect.
        - `pico.in.rect (out: Rect, in: Rect) -> Rect`
    - **pico.in.pos**: Composes a child position onto a parent rect.
        - `pico.in.pos (out: Rect, in: Pos) -> Pos`
    - **pico.in.dim**: Composes a child dimension onto a parent rect.
        - `pico.in.dim (out: Rect, in: Dim) -> Dim`
- **pico.input**
    - **pico.input.delay**: Freezes execution for milliseconds.
        - `pico.input.delay (ms: integer) -> integer`
        - Returns elapsed time in milliseconds (delta time)
    - **pico.input.event**: Waits for an event.
        - `pico.input.event () -> Event, integer`
        - `pico.input.event (ms: integer) -> Event?, integer`
        - `pico.input.event (filter: string?) -> Event, integer`
        - `pico.input.event (filter: string?, ms: integer?) -> Event?, integer`
        - Returns event (or nil on timeout) and elapsed time in ms (delta time)
        - `filter`: `'quit'`, `'window.resize'`, `'key.dn'`, `'key.up'`,
          `'mouse.motion'`, `'mouse.button.dn'`, `'mouse.button.up'`, or
          `nil` for any event. The events that do not match are discarded.
        - `ms`: an integer (a number with no fractional part) from `0`, or
          `nil` or `-1` for no timeout.
        - These are the only forms. It is an error to pass an argument of
          another type (`pico.input.event('quit', '10')`), a number in the
          place of the filter when `ms` is also given
          (`pico.input.event(10, 20)`), an unknown filter, a timeout below
          `-1`, or a third argument.
        - In expert mode with an FPS, the forms with no `ms` also return
          `nil` when the frame expires (see `pico.set.expert`).
    - **pico.input.loop**: Blocks on event loop until quit.
        - `pico.input.loop ()`
- **pico.layer**: Creates layers from various constructors.
    - Each constructor receives a single table and evaluates to a new
      `Layer` (see [Lifetimes](#lifetimes)).
    - The parent `up` must be able to host children: the world, the window,
      a layer created by `pico.layer.empty`, or a sub-layer of those.
    - **pico.layer.world**: Evaluates to the world layer.
        - `pico.layer.world () -> Layer`
    - **pico.layer.window**: Evaluates to the window layer.
        - `pico.layer.window () -> Layer`
    - **pico.layer.empty**: Creates an empty layer.
        ```
        pico.layer.empty [
            up:     Layer,      -- parent layer (default: detached)
            clear:  boolean,    -- cascade-clear flag, requires up (default: false)
            dim:    Dim,        -- texture size (default: target w/h)
            tile:   Tile,       -- tile size (default: none) (see `pico.set.scene`)
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
    - **pico.layer.image**: Creates a layer from an image file.
        ```
        pico.layer.image [
            up:     Layer,      -- parent layer (default: detached)
            path:   string,     -- image file
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
    - **pico.layer.images**: Creates sub-layer images from a reference
        "sprite sheet" image.
        ```
        pico.layer.images [
            up:     Layer,      -- parent of the generated sub-layers
            path:   string,     -- sprite sheet image file
            sheet:  table,      -- grid or explicit spec (below)
            target: Rect,       -- scene.target placement of each sub-layer
        ] -> table              -- generated sub-layers
        ```
        - `target` has the meaning it has in the other constructors, and
          applies to every generated sub-layer: they all get the same
          placement in the parent, which is also where
          `pico.output.draw.layer(l)` draws each of them when it receives no
          `rect`. If absent, each sub-layer keeps the default placement of a
          `pico.layer.sub`.
        - `sheet`:
            - **Grid**: `[ '#', w: integer, h: integer, [n: integer] ]`
                - generates a vector with the sub-layers, from index `0`
                - uses left-to-right order, with `w` columns and `h` rows
                - `n` limits the count (default `w*h`)
            - **Explicit**: `[ '!', [name1: Rect, name2: Rect, ...] ]`
                - generates a table with a sub-layer for each given
                    `name=crop` pair, under the same `name`
        - The layer of the sheet itself is not returned: it lives while any
          of its sub-layers does.
    - **pico.layer.pixmap**: Creates a layer from a pixmap.
        ```
        pico.layer.pixmap [
            up:     Layer,      -- parent layer (default: detached)
            pixels: [[Color]],  -- pixel matrix (rows of colors)
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
        - The field `pixels` may also be named `pixmap`.
    - **pico.layer.screenshot**: Creates a layer from a screenshot of a
      layer.
        ```
        pico.layer.screenshot [
            up:     Layer,      -- parent layer (default: detached)
            sup:    Layer,      -- source layer to capture from (default: current)
            crop:   Rect,       -- area in sup's frame (default: full)
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
        - The fields `sup` and `crop` may also be named `src` and `rect`.
    - **pico.layer.sub**: Creates a sub-layer from a source layer.
        ```
        pico.layer.sub [
            up:     Layer,      -- parent layer (default: detached)
            sup:    Layer,      -- source layer to crop from
            crop:   Rect,       -- area in sup's frame (live view)
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
        - `sup` and `crop` are required.
        - `sup` cannot be a sub-layer itself.
        - While the sub-layer lives, `sup` cannot be resized (`dim` in
          `pico.set.scene`, `pico.set.dim`).
    - **pico.layer.text**: Creates a layer from text.
        ```
        pico.layer.text [
            up:     Layer,      -- parent layer (default: detached)
            dim:    Dim,        -- h: font height (resolves against `up`)
            text:   string,     -- text to render
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
        - uses the current pencil font and color.
        - `dim.w` is always inferred from the text, and must be absent
        - `text` may also be a number, and cannot be empty
    - **pico.layer.video**: Creates a layer from a video file.
        ```
        pico.layer.video [
            up:     Layer,      -- parent layer (default: detached)
            path:   string,     -- video file (Y4M format)
            target: Rect,       -- scene.target placement (default: fill parent)
        ] -> Layer
        ```
    - **pico.layer.free**: Releases a layer.
        - `pico.layer.free (layer: Layer)`
        - It is an error to free the world, the window, the current layer,
          or a layer with children or sub-layers.
- **pico.open**: Initializes pico and opens its window.
    ```
    pico.open [
        title:  string,     -- window title (default: built-in title)
        fs:     boolean,    -- fullscreen mode (default: false)
        show:   boolean,    -- window visibility (default: true)
    ]
    ```
    - `pico.open ()` uses all defaults.
    - The field `fs` may also be named `fullscreen` (`fs` prevails if both
      are given).
    - It is an error to open pico twice with no `pico.close` in between.
    - The current layer is the world.
- **pico.output**
    - **pico.output.clear**: Clears screen.
        - `pico.output.clear ()`
    - **pico.output.present**: Composites layers and presents buffer.
        - `pico.output.present ([layers: boolean])`
        - `layers`: when `true` (default), composites the window layer
          hierarchy onto `window.tex` before mirroring to the
          framebuffer; when `false`, mirrors only (raw, advanced).
        - In non-expert mode `layers` must be `true` (an error otherwise);
          non-expert auto-presents after each draw op.
    - **pico.output.screenshot**: Takes a screenshot of a layer.
        - `pico.output.screenshot (layer: Layer?, [path: string|rect: Rect,] [rect: Rect]) -> string`
        - `layer`: target layer; `nil` means current layer.
        - `path`: output file; `nil` (or omitted) uses a timestamped name.
        - `rect`: region in target layer's frame; `nil` (or omitted)
          captures full. Accepted at position 2 (no path) or 3.
        - Returns the path of the file.
        - Forms:
            - `pico.output.screenshot()` — cur, default path
            - `pico.output.screenshot(nil, "x.png")` — cur, given path
            - `pico.output.screenshot(nil, rect)` — cur, default path, rect
            - `pico.output.screenshot(L)` — layer L, default path
            - `pico.output.screenshot(L, "x.png")` — layer L, given path
            - `pico.output.screenshot(L, rect)` — layer L, default path, rect
            - `pico.output.screenshot(L, "x.png", rect)` — full form
        - Cur layer is preserved.
    - **pico.output.sound**: Plays sound.
        - `pico.output.sound (sound: Sound)`
        - `pico.output.sound (path: string)`
    - **pico.output.draw**
        - **pico.output.draw.image**: Draws image.
            - `pico.output.draw.image (path: string, rect: Rect)`
            - missing `w` or `h` are filled in the given `rect` table
        - **pico.output.draw.layer**: Draws a layer onto the current layer.
            - `pico.output.draw.layer (layer: Layer [, rect: Rect])`
            - `rect` is optional; when omitted (or `nil`), the layer's
              `scene.target` is used (full bounds in cur).
            - It is an error to draw the current layer onto itself.
        - **pico.output.draw.layers**: Composites the window layer hierarchy
          (window's children, including world) onto window.tex. Implicit
          in `pico.output.present(true)` (default) and in non-expert mode
          auto-present. Standalone use: compose without mirroring (e.g.,
          to sample composed `window.tex` mid-frame).
            - `pico.output.draw.layers ()`
        - **pico.output.draw.line**: Draws line.
            - `pico.output.draw.line (p1: Pos, p2: Pos)`
        - **pico.output.draw.oval**: Draws oval.
            - `pico.output.draw.oval (rect: Rect)`
            - missing `w` or `h` draws a circle based on the given `h` or `w`
        - **pico.output.draw.pixel**: Draws pixel.
            - `pico.output.draw.pixel (pos: Pos)`
        - **pico.output.draw.pixels**: Draws multiple pixels.
            - `pico.output.draw.pixels (ps: [Pos])`
        - **pico.output.draw.poly**: Draws polygon.
            - `pico.output.draw.poly (ps: [Pos])`
        - **pico.output.draw.rect**: Draws rectangle.
            - `pico.output.draw.rect (rect: Rect)`
            - missing `w` or `h` draws a square based on the given `h` or `w`
        - **pico.output.draw.text**: Draws text.
            - `pico.output.draw.text (text: string, rect: Rect)`
            - `rect.h` is required; a missing `w` is inferred from the text
            - `text` may also be a number
            - uses the current pencil font and color
        - **pico.output.draw.tri**: Draws triangle.
            - `pico.output.draw.tri (p1: Pos, p2: Pos, p3: Pos)`
        - **pico.output.draw.video**: Draws video frame.
            - `pico.output.draw.video (path: string, rect: Rect) -> boolean`
            - Returns `false` at the end of the video.
- **pico.quit**: Pushes a quit event to terminate the application.
    - `pico.quit ()`
- **pico.set**: Setters for various properties and settings.
    - omitted table fields keep their current values
    - **pico.set.aids**: Toggles the automatic aids (default: on).
        - `pico.set.aids (on: boolean)`
        - The aids are the automatic termination of the program when the
          window is closed (out of expert mode, and out of `pico.input.loop`),
          and the `CTRL` key bindings for the world: `+`/`-` (zoom), arrow keys
          (scroll), `g` (grid), and `s` (screenshot).
    - **pico.set.dim**: Sets both window and world to the same dimensions.
        - `pico.set.dim (dim: Dim)`
        - The mode `'%'` is invalid.
        - It is an error if the window or the world has live sub-layers (see
          `pico.set.scene`).
    - **pico.set.effect**: Sets effect configuration.
        ```
        pico.set.effect [
            alpha:  integer,    -- layer opacity 0-255
            color:  Color,      -- background (clear) color
            flip:   Flip,       -- mirror the layer
            grid:   boolean,    -- show the grid aid
            rotate: Rotation,   -- rotation angle + anchor
        ]
        ```
    - **pico.set.expert**: Toggles expert mode.
        - `pico.set.expert (on: boolean [, fps: integer|boolean]) -> integer`
        - fps: omitted, `false`, or `0` = wait forever, `true` or `-1` = as
          fast as possible, `N>0` = fixed FPS.
        - Returns frame period in ms: `-1` = block forever, `0` = immediate, `N>0` = frame period
    - **pico.set.layer**: Switches the target layer.
        - `pico.set.layer (layer: Layer) -> Layer?`
        - Returns the previous layer (useful for save/restore), or `nil` if
          its value is gone (see [Lifetimes](#lifetimes)).
        - `layer` must be a layer; `nil` errors. The two predefined
          layers are `pico.layer.world()` (default) and
          `pico.layer.window()`.
    - **pico.set.mouse**: Sets mouse cursor position. `pos` is
      interpreted in `layer`'s frame and projected to window for the
      SDL warp. `layer` defaults to cur when omitted or `nil`.
        - `pico.set.mouse ([layer: Layer?,] pos: Pos)`
        - `pos.mode`: `'!'` pixels, `'%'` percentage, `'#'` tiles
        - Forms:
            - `pico.set.mouse(pos)` — cur
            - `pico.set.mouse(nil, pos)` — explicit nil = cur
            - `pico.set.mouse(pico.layer.window(), pos)` — given layer's frame
    - **pico.set.pencil**: Sets pencil configuration.
        ```
        pico.set.pencil [
            color:  Color,              -- drawing color
            font:   Font|string|false,  -- font, TTF path, or false (built-in)
            style:  'fill'|'stroke',    -- shape drawing style
        ]
        ```
        - The pencil belongs to the current layer.
    - **pico.set.scene**: Sets scene configuration.
        ```
        pico.set.scene [
            dim:    Dim,        -- texture size (recreates and clears)
            source: Rect,       -- visible crop of the layer
            clip:   Rect,       -- drawing clip region
            target: Rect,       -- placement in parent (resolved at each use)
            tile:   Tile,       -- tile size
            clear:  boolean,    -- cascade-clear flag
        ]
        ```
        - if `tile` is given, it is resolved in conjunction with `dim`:
            - `dim '!'` / `tile '!'`: both in px
            - `dim '!'` / `tile '#'`: `tile` counts cells (tile = ⌊dim/t⌋)
            - `dim '!'` / `tile '%'`: `tile` is a fraction (tile = ⌊t·dim⌋)
            - `dim '#'` / `tile '!'`: `dim` counts cells (dim = d·tile)
            - `dim '#'` / `tile '#'|'%'`: invalid modes
        - `dim '%'` is invalid.
        - `dim` is an error (`cannot resize a layer with live sub-layers`)
          while a sub-layer of the layer (`pico.layer.sub`,
          `pico.layer.images`) is alive: the sub-layers borrow the texture
          that `dim` replaces. It is allowed again when they are gone.
        - `clear=true` is invalid for the world, the window, and sub-layers.
    - **pico.set.video**: Sets video frame.
        - `pico.set.video (video: Layer, frame: integer) -> boolean`
        - `video` must be a layer created by `pico.layer.video`.
        - Returns `false` if the frame is past the end of the video.
    - **pico.set.window**: Sets window configuration.
        ```
        pico.set.window [
            fullscreen: boolean,    -- fullscreen mode
            show:       boolean,    -- window visibility
            title:      string,     -- window title
        ]
        ```
- **pico.sound**
    - **pico.sound.load**: Loads a sound from a file.
        - `pico.sound.load (path: string) -> Sound`
        - The sound is played with `pico.output.sound(s)`.
    - **pico.sound.free**: Releases a sound.
        - `pico.sound.free (sound: Sound)`
- **pico.vs**
    - Collision checks.
      Each side has the canonical shape `(Lx, vx)` where `Lx` is a direct
      child of cur (or absent for cur itself) and
      `vx` is a `Pos` or `Rect` value relative to `Lx`.
    - Args are matched left-to-right against the 4-slot template
      `(L1, v1, L2, v2)`. Both explicit `nil`s and trailing omissions
      are accepted; a mismatched type leaves the slot empty without
      consuming the arg, so `(L1, L2)`, `(v1, v2)`, `(L1, v2)`, etc.
      are all valid shortenings.
    - When a `rect` slot is absent (both `Lx` and `vx`) it defaults to
      the bounds of cur (`scene.target`). `pos` slots have no default and
      must always be supplied.
    - **pico.vs.pos.pos**: True if two points fall on the same pixel
      (after integer rounding in cur).
        - `pico.vs.pos.pos (L1: Layer?, p1: Pos, L2: Layer?, p2: Pos) -> boolean`
        - `p1` and `p2` are required.
    - **pico.vs.pos.rect**: True if a point is inside a rectangle.
        - `pico.vs.pos.rect (L1: Layer?, p1: Pos, L2: Layer?, r2: Rect?) -> boolean`
        - `p1` is required; `r2` defaults to cur's bounds (or `L2`'s
          bounds when `L2` is set and `r2` is absent).
    - **pico.vs.rect.pos**: True if a point is inside a rectangle
      (mirror of `pos.rect`).
        - `pico.vs.rect.pos (L1: Layer?, r1: Rect?, L2: Layer?, p2: Pos) -> boolean`
        - `p2` is required; `r1` defaults to cur's bounds (or `L1`'s
          bounds when `L1` is set and `r1` is absent).
    - **pico.vs.rect.rect**: True if two rectangles overlap.
        - `pico.vs.rect.rect (L1: Layer?, r1: Rect?, L2: Layer?, r2: Rect?) -> boolean`
        - All slots are optional; each missing rect side defaults to
          its layer's bounds (or cur's bounds when the layer is also
          absent). The 2-layer form `(L1, L2)` compares the bounds
          of both child layers.

## Reactive Mode

An imperative program calls `pico.open()`, draws, waits for input with
`pico.input.*`, and calls `pico.close()` (or leaves it to the end of the
program).

A reactive program calls `pico.open()` and awaits.
When the main chunk awaits (it does not terminate) and pico is open, the
program runs inside the loop of pico:

```
include "../pico.atm"
pico.open()
par {
    loop on :draw {
        pico.output.draw.rect [ '%', x=0.5, y=0.5, w=0.5, h=0.5 ]
    }
} with {
    val e = await :key.dn
    print(e.key)
}
```

The loop runs in expert mode, and leaves it on when it terminates:

- If the expert mode is off when the loop starts, the loop turns it on at 30
  FPS.
- If the program has turned it on before it awaits, the loop keeps its
  setting.
  `pico.set.expert(true,fps)` runs the loop at `fps`.
  `pico.set.expert(true)`, with no FPS, makes each frame wait for an input
  event with no timeout: while there are no events, there are no frames, the
  time does not advance (`await 1s` does not awake), and nothing is redrawn.
- A frame ends at its deadline or as soon as a real input event arrives, so
  that the FPS is the minimum rate: each event has a frame (and a `:draw`) of
  its own.

Each iteration of the loop is a frame, which emits to the program, in this
order:

| Event | Description |
|-------|-------------|
| `<number>` | the time passed since the previous frame, in microseconds, so that `await 1s`, `loop on 100ms`, and `loop dt on :clock` work |
| `:quit []` | the window was closed: the loop terminates |
| `:key.dn [key='A', ctrl=, shift=, alt=]` | a key was pressed |
| `:key.up [...]` | a key was released |
| `:mouse.motion ['!', x=, y=, anchor=, left=, right=, middle=]` | the mouse moved |
| `:mouse.button.dn [...]` | a mouse button was pressed |
| `:mouse.button.up [...]` | a mouse button was released |
| `:window.resize [w=, h=]` | the window was resized |
| `:draw` | to redraw the screen, between a clear and a present |

- The input events are the same [`Event`](#types) values of
  `pico.input.event`, such that `await :key.dn [key='Escape']` and
  `loop e on :mouse.button.dn {...}` match them.
- At most one real input event is emitted per frame: the others wait for the
  next frames.
  The scripted events of `PICO_ATM_KEYS` and `PICO_ATM_MOUSE` (see
  [Tests](#tests)) are emitted in addition, after the real event and before
  `:draw`: all the entries of the frame, the keys first, each list in its
  order.
- The time is only emitted if it is greater than zero: a frame in which `0ms`
  passed emits no time.
- The event `:draw` is a plain tag, not a table.
  The clear before it always applies to the world layer, whatever the
  current layer is when the program awaits, and the current layer remains
  the same. As any clear, it cascades to the descendants of the world created
  with `clear=true`: the other layers keep what was drawn on them in the
  previous frames.
- The loop terminates with `:quit`, with the program (when the main chunk
  terminates), or with `pico.close()`.
  After `:quit`, the program is aborted: only the tasks that await `:quit`
  react to it.

## Tests

The next environment variables run the [reactive mode](#reactive-mode) with no
interaction:

| Variable | Description |
|----------|-------------|
| `PICO_ATM_FRAMES=n:ms` | runs `n` frames, then emits `:quit`; if `ms` is not `0`, each frame lasts exactly `ms` milliseconds and does not wait |
| `PICO_ATM_KEYS=f:dn:A,...` | presses (`dn`) or releases (`up`) keys at the given frames, as `:key.dn` and `:key.up` events with the given key names |
| `PICO_ATM_MOUSE=f:dn:x:y,...` | presses (`dn`) or releases (`up`) the left button, or only moves the mouse (`mv`), at the pixel `(x,y)` of the window at the given frames, as `:mouse.button.dn`, `:mouse.button.up`, and `:mouse.motion` events |
| `PICO_ATM_SHOT=f:x.png,...` | saves the window to the given files at the given frames, after the present |

Frames count from `1`.
As an example, the next command runs 12 frames of `20ms`, presses `A` at
frame 4, releases it at frame 6, clicks at the pixel `(250,100)` of the window
at frame 7, and saves the window at frame 8:

```
$ PICO_ATM_FRAMES=12:20 PICO_ATM_KEYS=4:dn:A,6:up:A \
    PICO_ATM_MOUSE=7:dn:250:100,7:up:250:100 PICO_ATM_SHOT=8:out.png \
    pico-atmos game.atm
```

- With `PICO_ATM_FRAMES=n:0`, the frames are the real ones, which wait as the
  expert mode determines: after `pico.set.expert(true)` with no FPS, a frame
  only happens on a real input event (see [Reactive Mode](#reactive-mode)).
- A scripted key has `ctrl`, `shift`, and `alt` set to `false`.
- A scripted mouse event has the fields of a real one, in pixels of the
  window: `['!', x=, y=, anchor=[x=0.5,y=0.5], left=, right=false,
  middle=false]`.
  With the anchor at the center of the pixel, the entry `dn:250:100` has
  `x=250.5` and `y=100.5`, as a real click on that pixel.
  `left` is `true` from a `dn` up to the next `up`, including the `mv` in
  between.
  A `dn` or `up` does not emit a `:mouse.motion` before it.
- From the first scripted mouse event on, `pico.get.mouse` answers with the
  scripted position and left button, in any layer and mode, until a real
  mouse event arrives or the program calls `pico.set.mouse`.
  The real cursor does not move.
- An invalid entry of `PICO_ATM_MOUSE` raises an error at its frame.

The next operations are the helpers of the visual tests of the binding
(`tst/*.atm`):

- **pico.check**: Saves the window to `$PICO_ROOT/c/tst/out/<name>.png`.
    - `pico.check (name: string)`
    - `PICO_ROOT` is the absolute root of the repository, which the script
      `pico-atmos` exports to the program, such that the call works from any
      directory.
      If the variable is not set (the program runs without the script), the
      directories are `../c/tst/out` and `../c/tst/asr`, relative to the
      current directory.
    - If the environment variable `PICO_CHECK_INT` is set, waits for a key
      press.
    - If the environment variable `PICO_CHECK_ASR` is set, compares the file
      with the reference image `$PICO_ROOT/c/tst/asr/<name>.png` (or
      `<name>-CI.png`), and raises an error if they differ.
- **pico.equal**: True if two numbers are close enough (they differ by less
  than `0.001`).
    - `pico.equal (a: number, b: number) -> boolean`
