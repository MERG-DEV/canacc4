# Test reboot into bootloader on receipt of CBUS command in SLiM mode.

define(test_name, slim_reboot_test)dnl

set_up_test_simulation

set_number_of_events(5)

run_test
