# Test FLiM mode does not learn using switches and events.

Device PIC18F2480
Hwtool SIM
Program "../dist/default/production/canacc4.production.cof"
Stim "./scl/flim_learn_test.scl"
Break *0 1

# Set CAN Id and module status
Write /e 0x0 0x0C 0x08

# Set Node Id
Write /e 0x02 0x04 0x02

Run
Wait
Quit
