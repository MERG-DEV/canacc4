# Test reboot into bootloader on receipt of CBUS command in SLiM mode.

set_test_name()dnl

set_up_test_simulation

set_number_of_events(5)

run_test
