# Test switch from FLiM to SLiM mode.

define(test_name, flim_slim_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_number_of_events(5)

run_test
