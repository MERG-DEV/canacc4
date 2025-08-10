# Test boot into SLiM mode with maximum number of events

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_data_for_maximum_events

run_test
