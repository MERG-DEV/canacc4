# Test boot into SLiM mode with events does not clear and initialise events.

define(test_name, slim_boot_with_events_test)dnl

set_up_test_simulation

set_data_for_five_events

run_test
