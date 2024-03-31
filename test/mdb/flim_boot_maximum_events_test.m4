# Test boot into FLiM mode with maximum number of events

define(test_name, flim_boot_maximum_events_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_maximum_events

run_test
