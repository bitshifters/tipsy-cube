# tipsy-cube: start here

Tipsy Cube, a small Acorn Archimedes intro (ARM2/ARM250, 2 MB) by Bitshifters & Slipstream for the FieldFX 2022 New Year's Demostream (6th in Random Demo). This repo is the clean release record: a single-commit snapshot cut down to only what the intro uses. It rebuilds the released `!Tipsy` byte for byte.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/tipsy-cube (public) |
| Origin | Snapshot of the old tipsy-cube master (192a6b7, a GitHub fork of kieranhj/proto-arc) made on 2026-11-27. Full development history is in proto-arc at tag `archive/tipsy-cube-main`. |
| Local path | D:\bitshifters\tipsy-cube |
| Branch | main (only branch) |
| Prod page | https://bitshifters.github.io/posts/prods/bs-tipsy-cube.html (download `bs-tipsy-cube.zip`: an ADFS E floppy image holding `!Tipsy`) |

## What's in here

- `tipsy-cube.asm`: the intro; `lib\`: rubber cube, 3D scene, polygon/span renderer, maths, MODE 9 screen/palette, RasterMan rasters, scroller, GNU Rocket sync player; `lib\loader.asm` + `lib\arc-shrinkler.asm`: the `!RunImage` loader that unpacks `Demo`.
- `data\rocket\`: sync tracks plus the Rocket editor project; `data\music\arcchoon.mod`; `data\gfx\Fine.png` (scrolltext font).
- `folder\`: the app's static files (`!Run`, `!Help`, `!Sprites`, MemAlloc, QTM 1.46c, RasterMan 0.29). Marked `-text` in `.gitattributes` so they stay byte-exact (`!Run` is CRLF, `!Help` LF, as released).
- `bin\`: vasm, vlink, Shrinkler (+ MinGW DLLs), snmake, `sine_table.py`, `png2arc_font.py`, `arc.py`, `png.py`.

## Build and run

- `make` (or `make.bat`): release build of `!Tipsy`. Verified 2026-11-27, from a fresh clone, as byte-identical to the files on the released disc; SHA-256s are in README.md.
- `make debug` (`_DEBUG=1`), `make deploy` (to `..\arculator\hostfs\Builds`; override with `make.bat deploy HOSTFS=...`), `make clean`.
- Needs `python.exe` (Python 3). Use cmd / Windows Terminal, not Git Bash.
- Run `!Tipsy` in Arculator (`D:\bitshifters\arculator`), A3010 preset.

## Local changes

- None.

## Status and next steps

- Done: the release record. Changes from the old tree: removed the unused logo (`_DRAW_LOGO`) and sqrt (`_INCLUDE_SQRT`) code, unused lib modules (lighting, lz4-decode, mode9-plot, sqrt), the logo conversion and unused tools/data; the build is now `Makefile.mk` (was `make.bat` + `make_assets.bat`); `_DEBUG` can be set from the command line.
- The build doesn't make the ADF disc image that was published.

## See also

- README.md; `D:\archie\mine\proto-arc` (framework, full history); `D:\bitshifters\stniccc-archie` (where proto-arc came from).
