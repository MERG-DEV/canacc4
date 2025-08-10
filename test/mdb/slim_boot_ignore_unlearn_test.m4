# Test boot into SLiM mode with events when both learn and unlearn switches are
# set does not clear and initialise events.

set_test_name()dnl

set_up_test_simulation

set_data_for_five_events

run_test
