# Test SLiM ignores CBUS enumerate request.

Device PIC18F2480
Hwtool SIM
Program "../dist/default/production/canacc4.production.cof"
Stim "./scl/slim_enumerate_test.scl"
Break *0 1

Run
Wait
Quit
