# Test learn fails when no event space left in SLiM mode.

define(test_name, slim_learn_short_no_space_test)dnl

set_up_test_simulation

set_data_for_all_but_one_events

run_test
