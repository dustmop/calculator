# Calculator.nes

This is a simple calculator ROM, meant to demonstrate various NES homebrew
techniques.

The interface allows entry of two 8-bit numbers, and can add them together,
without any regard for handling overflow correctly.

A unit test exists for the decimal conversion routine, and verifies that the
function works for every possible input.


# Controls

- Up and down on the D-pad move the cursor between the two input numbers.
- Left and right on the D-pad move the cursor to different digits.
- A and B increase or decrease, respectively, the currently selected digit.
- Start adds the two numbers together and stores the result in the sum.


# Building

Install ca65 and run `make`. Build artifacts are kept in a directory named
".b/".


# Testing

Install a lisp implementation (tested with sbcl, clisp, ecl).

Install [quicklisp](http://www.quicklisp.org/beta/).

Get [cl-6502](https://github.com/redline6561/cl-6502). You may need to run
`(ql:update-dist "quicklisp")` first, then `(ql:quickload 'cl-6502)`.

Get [nes_unit_testing.lisp](https://github.com/dustmop/nes_unit_testing), put
it in the current directory so it can be loaded.

Run `./run_tests.sh` (assumes sbcl)

Running tests the first time may be slow, due to compile times.


# Windows

Install [Clozure CL](http://ccl.clozure.com/download.html), then follow the
above directions for cl-6502 and nes_unit_testing.lisp.

Run `windows_run_tests.bat` (assumes ccl)

Running tests the first time may be slow, due to compile times.
