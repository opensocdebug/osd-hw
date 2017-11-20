"""
    test_stm
    ~~~~~~~~

    Cocotb-based unit test for the System Trace Module (STM)

    :copyright: Copyright 2017 by the Open SoC Debug team
    :license: MIT, see LICENSE for details.
"""

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge

from osdtestlib.debug_interconnect import NocDriver, RegAccess, DiPacket
from osdtestlib.soc_interface import StmTraceGenerator
from osdtestlib.exceptions import *

import random

# DI address of the tested STM module
MODULE_DI_ADDRESS = 1

# DI address of the sending module
SENDER_DI_ADDRESS = 0

# Number of trace events to generate during the test
TRACE_EVENT_TEST_COUNT = 1000


@cocotb.coroutine
def _assert_reg_value(dut, regaddr, exp_value):
    """ Assert that a register contains an expected value """
    access = RegAccess()
    rx_value = yield access.read_register(dut=dut, dest=MODULE_DI_ADDRESS,
                                          src=SENDER_DI_ADDRESS,
                                          word_width=16,
                                          regaddr=regaddr)

    if rx_value != exp_value:
        raise TestFailure("Read value 0x%04x from register %x, expected 0x%04x."
                          % (rx_value, regaddr, exp_value))


@cocotb.coroutine
def _assert_trace_event(dut, trace_id, trace_value):
    """
    Stimuli on the trace port will be generated once to trigger the emission
    of a new debug event packet which will be read and evaluated.
    """

    generator = StmTraceGenerator()
    driver = NocDriver()

    # Build expected packet
    expected_packet = DiPacket()
    exp_payload = [0, 0, trace_id]
    payload_words = int(dut.XLEN.value.integer / 16)
    for w in range(0, payload_words):
        exp_payload.append(trace_value >> (w * 16) & 0xFFFF)

    expected_packet.set_contents(dest=SENDER_DI_ADDRESS,
                                 src=MODULE_DI_ADDRESS,
                                 type=DiPacket.TYPE.EVENT.value,
                                 type_sub=0,
                                 payload=exp_payload)

    # Build comparison mask for expected packet
    # Ignore flits 0 and 1 with timestamp
    exp_payload_mask = [1] * len(exp_payload)
    exp_payload_mask[0] = 0
    exp_payload_mask[1] = 0

    yield generator.trigger_event(dut, trace_id, trace_value)
    rcv_pkg = yield driver.receive_packet(dut)

    if not rcv_pkg.equal_to(dut, expected_packet, exp_payload_mask):
        raise TestFailure("The STM generated an unexpected debug event packet!")


@cocotb.coroutine
def _activate_module(dut):
    """
    Set the MOD_CS_ACTIVE bit in the Control and Status register to 1 to
    enable emitting debug event packets.
    """

    access = RegAccess()

    yield access.write_register(dut=dut, dest=MODULE_DI_ADDRESS,
                                src=SENDER_DI_ADDRESS,
                                word_width=16,
                                regaddr=DiPacket.BASE_REG.MOD_CS.value,
                                value=1)


@cocotb.coroutine
def _init_dut(dut):
    # Setup clock
    cocotb.fork(Clock(dut.clk, 1000).start())

    # Dump design parameters for debugging
    dut._log.info("PARAMETER: XLEN is %d" % dut.XLEN.value.integer)
    dut._log.info("PARAMETER: REG_ADDR_WIDTH is %d" %
                  dut.REG_ADDR_WIDTH.value.integer)

    # Reset
    dut._log.info("Resetting DUT")
    dut.rst <= 1

    dut.id <= MODULE_DI_ADDRESS

    dut.debug_out_ready <= 1
    dut.trace_valid <= 0

    for _ in range(2):
        yield RisingEdge(dut.clk)
    dut.rst <= 0


@cocotb.test()
def test_stm_base_registers(dut):
    """
    Read the 5 base registers and compare the response with the desired value
    """

    yield _init_dut(dut)

    dut._log.info("Check contents of MOD_VENDOR")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_VENDOR.value, 1)

    dut._log.info("Check contents of MOD_TYPE")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_TYPE.value, 4)

    dut._log.info("Check contents of MOD_VERSION")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_VERSION.value, 0)

    dut._log.info("Check contents of MOD_CS")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_CS.value, 0)

    dut._log.info("Check contents of MOD_EVENT_DEST")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_EVENT_DEST.value,
                            SENDER_DI_ADDRESS)


@cocotb.test()
def test_stm_activation(dut):
    """
    Check if STM is handling the activation bit correctly
    """

    yield _init_dut(dut)

    dut._log.info("Check contents of MOD_CS")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_CS.value, 0)

    yield _activate_module(dut)

    dut._log.info("Check contents of MOD_CS")
    yield _assert_reg_value(dut, DiPacket.BASE_REG.MOD_CS.value, 1)


@cocotb.test()
def test_stm_trace_events(dut):
    """
    Check if STM properly generates trace events
    """

    yield _init_dut(dut)

    yield _activate_module(dut)

    for _ in range(0, TRACE_EVENT_TEST_COUNT):
        # Randomly wait between trace events
        for _ in range(0, random.randint(0, 100)):
            yield RisingEdge(dut.clk)

        trace_id = random.randint(0, 2**16 - 1)
        trace_value = random.randint(0, 2**32 - 1)

        yield _assert_trace_event(dut, trace_id, trace_value)
