# Test SLiM ignores CBUS enumerate request.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

run_test
