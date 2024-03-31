# Test first time boot into SLiM mode initialises with no events.

define(test_name, slim_boot_test)dnl
include(common.inc)dnl

set_up_test_simulation

run_test
