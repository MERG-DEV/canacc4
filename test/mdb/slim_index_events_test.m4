# Test CBUS Read All Events request ignored in SLiM mode as Node Number is zero.

define(test_name, slim_index_events_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_five_events

run_test
