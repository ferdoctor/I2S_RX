# I2S_RX
VHDL design for an I2S multi-channel receiver

This module implements a hardware I2S receiver with the capacity to interface with many I2S synchronized sources.  The module buffers the data in an internal FIFO and outputs it through a simple bus interface.  When enough data is buffered, the module raises the INT signal (which can be used to trigger an interrupt) to signal data is available and should be read.

This project is being move to github.  Note:  This is an old project and the testbench for the module got lost in the move; will upload as soon as I locate it.
