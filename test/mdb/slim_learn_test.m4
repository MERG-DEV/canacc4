# Test learn both short and normal on and off events for normal and inverse
# polarity in SLiM mode.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

run_test
