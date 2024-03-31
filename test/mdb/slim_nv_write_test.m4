# Test cannot modify node variables in SLiM.

define(test_name, slim_nv_write_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_five_events

run_test
