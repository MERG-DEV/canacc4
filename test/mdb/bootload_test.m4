# Test enter bootloader mode on powerup.

set_test_name()dnl

set_up_test_simulation

Write /e 0xFF 0xFF

run_test
