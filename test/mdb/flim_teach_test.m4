# Test FLiM mode can be taught using CBUS messages.

define(test_name, flim_teach_test)dnl

set_up_test_simulation

set_flim_CAN_id_and_module_status
set_flim_node_id

run_test
