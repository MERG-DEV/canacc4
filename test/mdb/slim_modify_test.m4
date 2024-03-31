# Test cannot modify events in SLiM.

define(test_name, slim_modify_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_five_events

run_test
