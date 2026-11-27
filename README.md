# Tipsy Cube (Acorn Archimedes)

Source code for **Tipsy Cube**, a small intro by Bitshifters & Slipstream for the Acorn Archimedes. It was released for the [FieldFX](https://field-fx.party/) 2022 New Year's Demostream, where it came 6th in the Random Demo compo.

- Prod page: https://bitshifters.github.io/posts/prods/bs-tipsy-cube.html
- Pouet: https://www.pouet.net/prod.php?which=93218
- Video: https://www.youtube.com/watch?v=FITT0qfel5Q

This repository is a snapshot of the source for the released build, cut down to only the code, data and tools the intro uses. The full development history, which grew out of the proto-arc prototype framework, is in [kieranhj/proto-arc](https://github.com/kieranhj/proto-arc) at tag `archive/tipsy-cube-main`.

## Credits

Kieran^Bitshifters, ToBach^Slipstream, Phoenix^Quantum.

Powered by the QTMTracker MOD player and RasterMan by Phoenix^Quantum (https://www.pi-star.co.uk). The executable is packed with Blueberry's [Shrinkler](https://github.com/kieranhj/arc-shrinkler) compressor.

## Running

You need an Archimedes with RISC OS 2 or 3.1, 2 MB of RAM and an ARM250 or faster. On an 8 MHz ARM2 it is likely to stutter. Under emulation use [Arculator](http://b-em.bbcmicro.com/arculator/) v2.1 or later: emulate an A3010 and set the sound output filter to "more reduced".

For the best audio on real hardware, remove the hardware low-pass filter by following the instructions in this [thread](https://stardot.org.uk/forums/viewtopic.php?f=16&t=13630).

## Building

Builds on Windows, from cmd or Windows Terminal (not Git Bash).

You need Python 3 on the PATH as `python.exe`. The PNG reader (`bin/png.py`, pypng) is bundled, so no packages are needed.

The assembler (vasm), linker (vlink), Shrinkler (with its MinGW DLLs) and make (`snmake.exe`) are in `bin/`.

| Command | Builds |
|---|---|
| `make` or `make.bat` | Release build: the `!Tipsy` app folder, with the loader as `!RunImage` and the Shrinkler-packed intro as `Demo`. |
| `make.bat debug` | The same, assembled with `_DEBUG=1`. |
| `make.bat deploy` | Copies `!Tipsy` to `..\arculator\hostfs\Builds`. Use `make.bat deploy HOSTFS=path` to copy somewhere else. |
| `make.bat clean` | Removes `build` and `!Tipsy`. |

The release build reproduces the released `!Tipsy` byte for byte. SHA-256 of the released files:

```
395b6f3e1f9d4d9e51e54197b788e11d666011fbdb1da145d0e294b727a2b42f  !Help
12b360ada74e628fdcb9d2c2579c1de881120dff55555a4ed3168f398deca8a1  !Run,feb
12ec7e8d3f0c5516378d9f0b893e9e3faf5d94d54c24aaf5ea8c1324a1045d4b  !RunImage,ff8
2f95b783f2d555b47e0a89f4ef590b5e5b6e3fad47dd7133a01675819f10a864  !Sprites,ff9
10efe5edf96deb4fd2bb21a90e7a099a11e403a725530fb50ce37c383d81f087  Demo,ffd
e799448b746e544bfa6c4ca720e4e88d61a897c99da0d18a411ba795647a9c8a  MemAlloc,ffa
6b53a9144f296aadd267e80252cee8e25155b8588f0c0829d06143cfc70c6a53  QTM146c_24,ffa
261df117124b192b1b3d758ff1d834a412972e6c39d61fb551c6cbe8aadeecdd  RasterM29,ffa
```

The release itself is `bs-tipsy-cube.zip`, holding an 800 KB ADFS E-format floppy image (`tipsy-cube.adf`) with `!Tipsy` on it. The build doesn't make the disc image.

The files in `folder/` go into the app as they are, so `.gitattributes` keeps them byte-exact on checkout: `!Run` has CRLF line endings and `!Help` has LF, as on the released disc.

## Release history

| Version | Date | Notes |
|---|---|---|
| Release | 2023-01-01 | The only published version. Built from the source as at commit `3815e60` ("Update readmes."), which is in the history at proto-arc tag `archive/tipsy-cube-main`. |

## Layout

| Path | Contents |
|---|---|
| `tipsy-cube.asm` | The intro: setup, main loop, sequence, scrolltext and data. |
| `lib/` | The rubber cube, 3D scene and polygon/span renderer, maths (sine, vector, matrix, divide), MODE 9 screen and palette, RasterMan rasters, scroller and the GNU Rocket sync player. |
| `lib/loader.asm`, `lib/arc-shrinkler.asm` | The `!RunImage` loader that unpacks `Demo` with Shrinkler. |
| `data/rocket/` | The GNU Rocket sync tracks the intro plays, plus the editor project (`rubber_cube.project`) they were made with. |
| `data/music/arcchoon.mod` | The music, by ToBach. |
| `data/gfx/Fine.png` | The scrolltext font. |
| `folder/` | The `!Tipsy` app's static files: `!Run`, `!Help`, `!Sprites`, and the MemAlloc, QTM and RasterMan modules. |
| `bin/` | Tools, and the Python 3 scripts that make the sine table and convert the font. |

## License

The code is MIT licensed (see `LICENSE`). The music, graphics and the QTM, RasterMan and MemAlloc modules belong to their authors.
