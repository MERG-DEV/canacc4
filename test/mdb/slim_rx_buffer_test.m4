# Test all Rx buffers are used in SLiM mode.

define(test_name, slim_rx_buffer_test)dnl

set_up_test_simulation

set_number_of_events(5)

run_test
