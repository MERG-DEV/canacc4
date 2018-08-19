CAN_ACC4 Firmware Rev J

Hardware
--------

	CAN_ACC4 (Original PCB)
	CAN_ACC4_2 (with Voltage Doubler)

This firmware update allows multiple overlapping events to be sent to a CAN_ACC4 board
without losing any changes.

It is suitable for both the original CAN_ACC4 board (Kit #84) AND the newer ACC4_2 board.

Upgrade Procedure
-----------------
This release adds a configurable "recharge" time, which is stored in NV9. When upgrading from
older firmware, this will initially have a zero recharge time, so use FCU to set NV9 to 20,
giving a recharge time of 200mS.

Note that an upgraded board (_1 or _2) will be shown in FCU as a _2 board following the upgrade.

Configuration
-------------
NV1..8 control the time for Outputs 1A,1B,2A,2B,3A,3B,4A,4B respectively, all in units of 10mS.
Unlike the earlier firmware, the output on time is very precise. If any of these times are set
to zero, the output will be asserted then the next event processed immediately.
In practice, the capacitor(s) discharge very quickly, and there will be little difference
observed with values between 1 (10mS) and 5 (50mS).

NV9 controls the recharge time, again in units of 10mS. The default of 200mS will work for most
purposes.

Operation
---------
Incoming events set or reset one or more bits in an 8 bit register, one for each output.
On each 10mS timer interrupt, this register is checked, and the first output is changed.
After the appropriate output time has expired, the charger is turned back on, then after
the recharge time has expired, the register is again checked and the next output is processed.
If events are sent to the board faster than they can be processed, each pair of outputs
will always be set to the LAST state received.

Credits
-------
Thanks to Roger Healey for his help with this change, and to Mike Bolton for the original design.

Phil Wheeler
M3645
9-Jan-12
