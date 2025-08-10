# Test learn fails when no event space left in SLiM mode.

set_test_name()dnl

set_up_test_simulation

set_data_for_all_but_one_events

run_test
