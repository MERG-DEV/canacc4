# Test switch from SLiM to FLiM mode.

define(test_name, slim_flim_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_number_of_events(5)

run_test
