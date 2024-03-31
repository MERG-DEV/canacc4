# Test boot into SLiM mode with maximum number of events

define(test_name, slim_boot_maximum_events_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_maximum_events

run_test
