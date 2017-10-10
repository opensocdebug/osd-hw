import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge
from hgext.largefiles.overrides import cmdutiladd

from NocDriver import NocDriver
from RegAccess import RegAccess
from EvalUtility import EvalUtility
from DiPacket import DiPacket

@cocotb.test()
def test_stm(dut):
    """
    Try accessing the design
    """

    # create an instance of the RegAccess and EvalUtility class
    access      = RegAccess()
    evaluation  = EvalUtility()


    # setup clock
    cocotb.fork(Clock(dut.clk, 1000).start())

    # reset
    dut._log.info("Resetting DUT")
    dut.rst <= 1

    dut.trace_valid <= 1
    dut.debug_out_ready <= 1
    dut.debug_in.valid <= 1

    # set module address to the second function parameter
    dut.id <= 1

    for _ in range(2):
        yield RisingEdge(dut.clk)
    dut.rst <= 0


    #===========================================================================
    #=========================================================Base register test
    #===========================================================================

    response = []

    #================================================================Test MOD_ID

    # specify how the result should look like
    expected_payload = []
    expected_payload.append(1)

    # specify which register to read from
    address = []
    address.append(0)

    # read out the register
    yield access.read_register(dut = dut, destination = 1, source = 0,
                               reg_width = 16, address = address,
                               response = response)

    yield evaluation.evaluate_response(dut = dut, response = response,
                                       destination = 1, source = 0,
                                       reg_width = 16,
                                       expected_payload = expected_payload)

    #===========================================================Test MOD_VERSION

    # specify how the result should look like
    expected_payload = []
    expected_payload.append(4)

    # specify which register to read from
    address = []
    address.append(1)

    # read out the register
    yield access.read_register(dut = dut, destination = 1, source = 0,
                               reg_width = 16, address = address,
                               response = response)

    yield evaluation.evaluate_response(dut = dut, response = response,
                                       destination = 1, source = 0,
                                       reg_width = 16,
                                       expected_payload = expected_payload)

    #============================================================Test MOD_VENDOR

    # specify how the result should look like
    expected_payload = []
    expected_payload.append(0)

    # specify which register to read from
    address = []
    address.append(2)

    # read out the register
    yield access.read_register(dut = dut, destination = 1, source = 0,
                               reg_width = 16, address = address,
                               response = response)

    yield evaluation.evaluate_response(dut = dut, response = response,
                                       destination = 1, source = 0,
                                       reg_width = 16,
                                       expected_payload = expected_payload)

    #================================================================Test MOD_CS
    #
    # expected_payload = []
    # expected_payload.append(1)
    #
    # address = []
    # address.append(3)
    #
    # # read out the register
    # yield access.read_register(dut = dut, destination = 1, source = 0,
    #                            reg_width = 16, address = address,
    #                            response = response)
    #
    # yield evaluation.evaluate_response(dut = dut, response = response,
    #                                    destination = 1, source = 0,
    #                                    reg_width = 16, 
    #                                    expected_payload = expected_payload)
    #
    #========================================================Test MOD_EVENT_DEST
    #
    # expected_payload = []
    # expected_payload.append(1)
    #
    # address = []
    # address.append(4)
    #
    # # read out the register
    # yield access.read_register(dut = dut, destination = 1, source = 0,
    #                            reg_width = 16, address = address,
    #                            response = response)
    #
    # yield evaluation.evaluate_response(dut = dut, response = response,
    #                                    destination = 1, source = 0,
    #                                    reg_width = 16,
    #                                    expected_payload = expected_payload)
    #===========================================================================

    for _ in range(1):
        yield RisingEdge(dut.clk)