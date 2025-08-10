# Test SLiM cannot be taught events using CBUS messages.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

run_test
