# Test reading back event variables in FLiM by indexed event

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_five_events

run_test
