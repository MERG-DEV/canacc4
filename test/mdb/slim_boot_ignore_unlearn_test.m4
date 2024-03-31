# Test boot into SLiM mode with events when both learn and unlearn switches are
# set does not clear and initialise events.

define(test_name, slim_boot_ignore_unlearn_test)dnl
include(common.inc)dnl

set_up_test_simulation

set_data_for_five_events

run_test
