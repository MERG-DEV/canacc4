# Test reading back events by index in FLiM

define(test_name, flim_event_by_index_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_five_events

run_test
