# Test enter bootloader mode on powerup.

define(test_name, bootload_test)dnl

set_up_test_simulation

Write /e 0xFF 0xFF

run_test
