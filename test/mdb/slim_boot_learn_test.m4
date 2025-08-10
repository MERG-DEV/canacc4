# Test boot into SLiM mode with events when learn switch is set does not
# clear and initialise events.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_data_for_five_events

run_test
