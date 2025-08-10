# Test first time boot into SLiM mode initialises with no events.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

run_test
