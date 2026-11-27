# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# The real build is Makefile.mk, run by bin\snmake.exe via make.bat.
.PHONY: all release debug deploy clean help
all: release

release debug deploy clean:
	cmd /c .\make.bat $@

help:
	@echo make         - release build: the !Tipsy app folder (Shrinkler-packed Demo)
	@echo make debug   - the same, assembled with _DEBUG=1
	@echo make deploy  - copy !Tipsy to ..\arculator\hostfs\Builds (make.bat deploy HOSTFS=path to override)
	@echo make clean   - remove build and !Tipsy
