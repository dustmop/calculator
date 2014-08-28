@echo off
wx86cl.exe --eval "(require :cl-6502)" --load "nes_unit_testing.lisp" --eval "(nes-unit-testing::all-tests-in-current-directory)" --eval "(quit)"
pause
