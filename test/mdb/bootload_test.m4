# Test enter bootloader mode on powerup.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

Write /e 0xFF 0xFF

run_test
