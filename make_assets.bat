@echo off
set PYTHON=C:\Dev\Python27\python.exe

%PYTHON% bin\sine_table.py 8192 65536 -o build\sine_8192.bin

%PYTHON% bin\png2arc_font.py -o build\font.bin --glyph-dim 8 8 --max-glyphs 96 data\gfx\Fine.png 9

%PYTHON% bin\png2arc.py -o build\logo.bin --use-palette data\raw\palette.bin data\gfx\bitshifters_teletext.png 9
