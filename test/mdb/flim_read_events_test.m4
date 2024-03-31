# Test reading back event varaibles in FLiM

define(test_name, flim_read_events_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_five_events

run_test
