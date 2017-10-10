import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge

class EvalUtility:
    """
    Provides an additional method to check if a register which was read out 
    contains the correct values
    """

    @cocotb.coroutine
    def evaluate_response(self, dut, response, destination, source, reg_width,
                          expected_payload):
        """Compare a received payload with its expectation value and output
           the result in the console
        Args:
            dut:                device under test.
            response:           read response of the debug module.
            destination:        id of the module which initially was the
                                destination.
            source:             id of the module which initially was the source.
            reg_width:          data width of the register the data was read 
                                from/written to.
            expected_payload:   expected received payload.
        Returns:
            -
        """

        result = 1

        if response[0] != source:
            # test failed if the response was intended for a different module
            raise TestFailure("Expected dest to be 0x%x, got 0x%x" %
                              (source, response[0]))
            result = 0

            if response[1] != destination:
                # test failed if the response was not sent from the target
                raise TestFailure("Expected src to be 0x%x, got 0x%x" %
                                  (destination, response[1]))
                result = 0

                for x in range(0, (reg_width/16)):
                    # step through the individual payload flits
                    if response[3 + x] != expected_payload[x]:
                        # test failed if a flit has the wrong value
                        raise TestFailure("Expected payload word %d to be 0x%x,\
                                          got 0x%x" % (x, expected_payload[x],\
                                                       response[3 + x]))
                        result = 0

        if result:
            # test was successful if none of the above mentioned errors occurred
            dut._log.info("Passed the test!")

            # clear the buffer for the next read_register()
            del response[:]

        for _ in range(1):
            yield RisingEdge(dut.clk)
