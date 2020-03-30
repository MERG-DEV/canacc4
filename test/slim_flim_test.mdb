# Test switch from SLiM to FLiM mode.

Device PIC18F2480
Hwtool SIM
Program "../dist/default/production/canacc4.production.cof"
Stim "./scl/slim_flim_test.scl"
Break *0 1

# Set free event space and number of events
Write /e 0x04 0x7b 0x05

Run
Wait
Quit
