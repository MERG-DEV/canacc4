# Test CBUS node parameter requests in SLiM mode.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_number_of_events(5)

run_test
