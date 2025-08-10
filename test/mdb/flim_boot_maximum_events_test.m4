# Test boot into FLiM mode with maximum number of events

set_test_name()dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_maximum_events

run_test
