# Test boot into FLiM mode.

define(test_name, flim_boot_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

run_test
