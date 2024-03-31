# Test cannot read back events by index in SLiM.

define(test_name, slim_event_by_index_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_five_events

run_test
