"""
    test_mam
    ~~~~~~~~

    Cocotb-based unit test for the Memory Access Module (MAM)

    :copyright: Copyright 2017 by the Open SoC Debug team
    :license: MIT, see LICENSE for details.
"""

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge

from osdtestlib.debug_interconnect import NocDriver, RegAccess, DiPacket
from osdtestlib.exceptions import *

import random

# DI address of the tested module
MODULE_DI_ADDRESS = 1

# DI address of the sending module
SENDER_DI_ADDRESS = 0


@cocotb.coroutine
def _init_dut(dut):

    # Setup clock
    cocotb.fork(Clock(dut.clk, 1000).start())

    # Dump design parameters for debugging
    dut._log.info("PARAMETER: DATA_WIDTH is %d" % dut.DATA_WIDTH.value.integer)
    dut._log.info("PARAMETER: ADDR_WIDTH is %d" % dut.ADDR_WIDTH.value.integer)
    dut._log.info("PARAMETER: MAX_PKT_LEN is %d" % dut.MAX_PKT_LEN.value.integer)
    dut._log.info("PARAMETER: REGIONS is %d" % dut.REGIONS.value.integer)
    for region in range(0, dut.REGIONS.value.integer):
        baseaddr = getattr(dut, "BASE_ADDR%d" % region).value.integer
        memsize = getattr(dut, "MEM_SIZE%d" % region).value.integer
        dut._log.info("PARAMETER: MEM_SIZE%d is %d" % (region, memsize))
        dut._log.info("PARAMETER: BASE_ADDR%d is %d" % (region, baseaddr))

    # Reset
    dut._log.info("Resetting DUT")
    dut.rst <= 1

    dut.id <= MODULE_DI_ADDRESS

    dut.debug_out_ready <= 1

    for _ in range(2):
        yield RisingEdge(dut.clk)
    dut.rst <= 0

@cocotb.test()
def test_mam_base_registers(dut):
    """
    Check if the base configuration registers have the expected values
    """

    access = RegAccess(dut)

    yield _init_dut(dut)
    yield access.test_base_registers(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                     [1, 3, 0, 1, SENDER_DI_ADDRESS])

@cocotb.test()
def test_mam_extended_registers(dut):
    """
    Check if the extended configuration registers have the expected values
    """

    access = RegAccess(dut)

    yield _init_dut(dut)
    yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                  DiPacket.MAM_REG.AW.value,
                                  dut.ADDR_WIDTH.value.integer)
    yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                  DiPacket.MAM_REG.DW.value,
                                  dut.DATA_WIDTH.value.integer)
    yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                  DiPacket.MAM_REG.REGIONS.value,
                                  dut.REGIONS.value.integer)

    for region in range(0, dut.REGIONS.value.integer):
        dut._log.info("Checking conf registers for region "+ str(region))
        region_basereg = 0x280 + region * 16
        region_baseaddr_basereg = region_basereg
        region_memsize_basereg = region_basereg + 4

        baseaddr_exp = getattr(dut, "BASE_ADDR%d" % region).value.integer
        memsize_exp = getattr(dut, "MEM_SIZE%d" % region).value.integer

        # REGION*_BASEADDR_*
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_baseaddr_basereg,
                                      baseaddr_exp & 0xFFFF)
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_baseaddr_basereg + 1,
                                      (baseaddr_exp >> 16) & 0xFFFF)
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_baseaddr_basereg + 2,
                                      (baseaddr_exp >> 32) & 0xFFFF)
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_baseaddr_basereg + 3,
                                      (baseaddr_exp >> 48) & 0xFFFF)

        # REGION*_MEMSIZE_*
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_memsize_basereg,
                                      memsize_exp & 0xFFFF)
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_memsize_basereg + 1,
                                      (memsize_exp >> 16) & 0xFFFF)
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_memsize_basereg + 2,
                                      (memsize_exp >> 32) & 0xFFFF)
        yield access.assert_reg_value(MODULE_DI_ADDRESS, SENDER_DI_ADDRESS,
                                      region_memsize_basereg + 3,
                                      (memsize_exp >> 48) & 0xFFFF)
