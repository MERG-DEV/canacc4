# Test learn fails when no event space left in SLiM mode.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_data_for_all_but_one_events

run_test
