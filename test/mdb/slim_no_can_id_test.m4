# Test all CAN Ids in use when switching from SLiM to FLiM mode.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

run_test
