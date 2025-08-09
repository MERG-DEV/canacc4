# Test all Tx priority raised if arbitration lost in SLiM mode.

define(test_name, slim_tx_arbitration_test)dnl

set_up_test_simulation

set_number_of_events(5)

run_test
