# Test CBUS node variable requests ignored in SLiM.

define(test_name, slim_nv_read_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_number_of_events(5)

run_test
