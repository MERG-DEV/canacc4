# Test event variables cannot be read by index in SLiM

define(test_name, slim_read_indexed_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_five_events

run_test
