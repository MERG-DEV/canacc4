# Test boot into FLiM mode with maximum number of events

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_maximum_events

run_test
