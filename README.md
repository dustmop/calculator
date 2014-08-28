calculator
==========

A sample NES rom demo to calculate addition, and demonstrate unit testing.

Build using `make`, and run calculator.nes on a Powerpak or in the emulator
of your choice.

To run tests, copy [nes_unit_testing.lisp](https://github.com/dustmop/nes_unit_testing) to the same directory, and run `./run_tests.sh`. The first run may
take extra time as sbcl compiles fasl files.
