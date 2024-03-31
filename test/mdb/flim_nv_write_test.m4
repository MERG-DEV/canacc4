# Test CBUS node variable requests in FLiM mode.

define(test_name, flim_nv_write_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_five_events

run_test
