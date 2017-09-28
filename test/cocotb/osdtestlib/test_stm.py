import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge
from hgext.largefiles.overrides import cmdutiladd

from modtestclasses import NoC_Driver
from modtestclasses import Reg_Access
from modtestclasses import Utility

BASE_REG_TEST = 0

@cocotb.test()
def test_stm(dut):
    """
    Try accessing the design
    """
    
    # create an instance of each class
    driver  = NoC_Driver()
    access  = Reg_Access()
    tool    = Utility()

    # initialize the testbench
    yield driver.init(dut = dut, ID = 1)
    
    # compare the values of the base registers with the desired values
    yield tool.ModuleSubTest_STM(dut = dut, test_driver = driver, 
                                 test_access = access, test_id = BASE_REG_TEST)