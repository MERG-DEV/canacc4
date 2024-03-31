# Test all CAN Ids in use when switching from SLiM to FLiM mode.

define(test_name, slim_no_can_id_test)dnl
include(common.inc)dnl

set_up_test_simulation

run_test
