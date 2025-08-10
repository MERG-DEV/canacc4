# Test CBUS Node Query request in FLiM mode as Node Number.

define(test_name, patsubst(__file__, {.m4},))dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_number_of_events(5)

run_test
