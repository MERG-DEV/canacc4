# Test event variables cannot be read in SLiM

define(test_name, slim_read_events_test)dnl

set_up_test_simulation

set_data_for_five_events

run_test
