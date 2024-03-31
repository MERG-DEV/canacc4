# Test learn fails when no event space left in FLiM mode.

define(test_name, flim_teach_no_space_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

set_data_for_all_but_one_events

run_test
