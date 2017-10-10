import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge

class NocDriver:
    """
    Deliver individual flits to a debug module and process their reaction
    """

    @cocotb.coroutine
    def transmit_flit(self, dut, data, last):
        """Transmit one flit between modules
            Args:
            dut:            device under test.
            data:           16 bit word which is to be transferred.
            last:           boolean value indicating if it is the last word
                            of a packet.
        Returns:
            -
        """

        # set the signals
        dut.debug_in.data <= data
        dut.debug_in.valid <= 1
        dut.debug_in.last <= last

        # wait for the active clock edge
        yield RisingEdge(dut.clk)
        # wait for the module to be ready to accept a data word
        while not dut.debug_in_ready.value:
            yield RisingEdge(dut.clk)
            dut.debug_in.valid <= 0
