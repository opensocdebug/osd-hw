"""
    osdtestlib.debug_interconnect
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Access the Debug Interconnect in OSD

    :copyright: Copyright 2017 by the Open SoC Debug team
    :license: MIT, see LICENSE for details.
"""

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure, ReturnValue
from cocotb.triggers import RisingEdge

from osdtestlib.exceptions import Error, RegAccessFailedException

from enum import IntEnum


class NocDriver:
    """
    Transport individual flits between debug modules and process their reaction
    """

    def __init__(self, dut):
        """Construct a new NocDriver object

        Args:
            dut (SimHandle): Entity interfacing with the bus
        """
        self.dut = dut

    @cocotb.coroutine
    def _send_flit(self, flit, is_last):
        self.dut.debug_in.data <= flit
        self.dut.debug_in.last <= is_last
        self.dut.debug_in.valid <= 1

        yield RisingEdge(self.dut.clk)

        while not self.dut.debug_in_ready.value:
            yield RisingEdge(dut.clk)

        self.dut.debug_in.valid <= 0

    @cocotb.coroutine
    def send_packet(self, packet):
        """Transmit a complete packet to a chosen debug module

        Args:
            packet:         debug interconnect packet
        """

        flits = packet.flits

        for i in range(0, len(flits)):
            is_last = (i == (len(flits) - 1))
            yield self._send_flit(flits[i], is_last)

    @cocotb.coroutine
    def receive_packet(self):
        """
        Receive a packet from the debug interconnect

        Returns:
            DiPacket
        """

        flits = []
        while True:
            yield RisingEdge(self.dut.clk)

            if self.dut.debug_out.valid.value:
                flits.append(self.dut.debug_out.data.value.integer)

                if self.dut.debug_out.last.value:
                    break

        pkg = DiPacket()
        pkg.flits = flits

        self.dut._log.debug("Received packet " + str(pkg))

        raise ReturnValue(pkg)


class DiPacket:
    """
    A single debug interconnect packet
    """

    class TYPE(IntEnum):
        """Packet types"""
        REG = 0
        PLAIN = 1
        EVENT = 2
        RESERVED = 4

    class TYPE_SUB(IntEnum):
        """Packet subtypes"""
        REQ_READ_REG_16 = 0
        REQ_READ_REG_32 = 1
        REQ_READ_REG_64 = 2
        REQ_READ_REG_128 = 3
        REQ_WRITE_REG_16 = 4
        REQ_WRITE_REG_32 = 5
        REQ_WRITE_REG_64 = 6
        REQ_WRITE_REG_128 = 7
        RESP_READ_REG_SUCCESS_16 = 8
        RESP_READ_REG_SUCCESS_32 = 9
        RESP_READ_REG_SUCCESS_6 = 10
        RESP_READ_REG_SUCCESS_128 = 11
        RESP_READ_REG_ERROR = 12
        NOT_DEFINED = 13
        RESP_WRITE_REG_SUCCESS = 14
        RESP_WRITE_REG_ERROR = 15

    class BASE_REG(IntEnum):
        """Base register addresses"""
        MOD_VENDOR = 0
        MOD_TYPE = 1
        MOD_VERSION = 2
        MOD_CS = 3
        MOD_EVENT_DEST = 4

    class SCM_REG(IntEnum):
        """SCM Register map"""
        SYSTEM_VENDOR_ID = 0x0200
        SYSTEM_DEVICE_ID = 0x0201
        NUM_MOD = 0x0202
        MAX_PKT_LEN = 0x0203
        SYSRST = 0x0204

    class MAM_REG(IntEnum):
        """MAM Register map"""
        AW = 0x0200
        DW = 0x0201
        REGIONS = 0x0202

    def __init__(self):
        self.dest = None
        self.src = None
        self.type = None
        self.type_sub = None
        self.payload = []

    def __str__(self):
        # Converts the individual words into a hexadecimal representation
        content = '[{}]'.format(', '.join(hex(x) for x in self.flits))
        return "DI packet:\n" + content

    @property
    def flits(self):
        """
        The data words this packet consists of

        :getter: Get the flits this packet consists of
        :setter: Take flits and set the packet contents based on it
        """

        flits = []
        flits.append(self.dest)
        flits.append(self.src)
        flits.append(self.type << 14 | self.type_sub << 10)
        flits.extend(self.payload)

        return flits

    @flits.setter
    def flits(self, flits):
        self.dest = flits[0]
        self.src = flits[1]
        self.type = (flits[2] & 0xC000) >> 14
        self.type_sub = (flits[2] & 0x3C00) >> 10
        self.payload = flits[3:]

    def set_contents(self, dest, src, type, type_sub, payload):
        """Populate the data fields of a packet

        Args:
            dest:           DI address of the target module
            src:            DI address of the sending module
            type:           packet type
            type_sub:       packet subtype
            payload:        payload
        """
        self.dest = dest
        self.src = src
        self.type = type
        self.type_sub = type_sub
        self.payload = payload

    def equal_to(self, dut, other_packet, mask):
        """Compares a packet with another packet and outputs if both are equal

        Args:
            dut:                device under test
            other_packet:       debug interconnect packet which this packet is
                                compared to
            mask:               list of boolean variables indicating which flits
                                of the payload are to be ignored
        Returns:
            True if the packets are equal (modulo the mask), False otherwise
        """

        if self.dest != other_packet.dest:
            dut._log.error("Expected DEST to be 0x%x, got 0x%x" %
                           (other_packet.dest, self.dest))
            return False

        if self.src != other_packet.src:
            dut._log.info("Expected SRC to be 0x%x, got 0x%x" %
                          (other_packet.src, self.src))
            return False

        if self.type != other_packet.type:
            dut._log.info("Expected TYPE to be %s, got %s" %
                          (self.TYPE(other_packet.type).name,
                           self.TYPE(self.type).name))
            return False

        if self.type_sub != other_packet.type_sub:
            if self.type == DiPacket.TYPE.REG.value:
                dut._log.info("Expected TYPE_SUB to be %s, got %s" %
                              (self.TYPE_SUB(other_packet.type_sub).name,
                               self.TYPE_SUB(self.type_sub).name))
            else:
                dut._log.info("Expected TYPE_SUB to be 0x%x, got 0x%x" %
                              (other_packet.type_sub, self.type_sub))
            return False

        for x in range(0, len(self.payload)):
            # The list indicates if the next flit is to be evaluated
            if mask[x] and self.payload[x] != other_packet.payload[x]:
                dut._log.info("Expected payload word %d to be 0x%x, got 0x%x" %
                              (x, other_packet.payload[x], self.payload[x]))
                return False

        return True


class RegAccess:
    """
    Access registers of debug modules
    """

    def __init__(self, dut):
        self.dut = dut
        self.driver = NocDriver(self.dut)

    @cocotb.coroutine
    def read_register(self, dest, src, word_width, regaddr):
        """
        Read a value from a specified register and return the read value to
        the user.

        Args:
            dest:           DI address of the target module.
            src:            DI address of the sending module.
            word_width:     choose between 16, 32, 64 and 128 bit register
                            access.
            regaddr:        address of the register the value is to be read
                            from.

        Returns:
            Value read from the register
        """
        tx_packet = DiPacket()
        rx_packet = DiPacket()

        try:
            if word_width == 16:
                type_sub = DiPacket.TYPE_SUB.REQ_READ_REG_16.value
                exp_type_sub = \
                    DiPacket.TYPE_SUB.RESP_READ_REG_SUCCESS_16.value
            elif word_width == 32:
                type_sub = DiPacket.TYPE_SUB.REQ_READ_REG_32.value
                exp_type_sub = \
                    DiPacket.TYPE_SUB.RESP_READ_REG_SUCCESS_32.value
            elif word_width == 64:
                type_sub = DiPacket.TYPE_SUB.REQ_READ_REG_64.value
                exp_type_sub = \
                    DiPacket.TYPE_SUB.RESP_READ_REG_SUCCESS_64.value
            elif word_width == 128:
                type_sub = DiPacket.TYPE_SUB.REQ_READ_REG_128.value
                exp_type_sub = \
                    DiPacket.TYPE_SUB.RESP_READ_REG_SUCCESS_128.value
            else:
                raise RegAccessFailedException("An invalid register width " +
                                               "parameter was chosen!")

            tx_packet.set_contents(dest=dest, src=src,
                                   type=DiPacket.TYPE.REG.value,
                                   type_sub=type_sub, payload=[regaddr])

            yield self.driver.send_packet(tx_packet)

            # Get response
            rx_packet = yield self.driver.receive_packet()

            # Check response
            if rx_packet.dest != src:
                self.dut._log.info(str(src))
                self.dut._log.info(str(rx_packet))
                raise RegAccessFailedException("Expected destination to be "
                                               "0x%x, got 0x%x" %
                                               (src, rx_packet.dest))

            if rx_packet.src != dest:
                raise RegAccessFailedException("Expected source to be 0x%x, "
                                               "got 0x%x" %
                                               (dest, rx_packet.src))

            if rx_packet.type != DiPacket.TYPE.REG.value:
                raise RegAccessFailedException("Expected type to be %s, got %s"
                                               % (DiPacket.TYPE.REG.name,
                                                  DiPacket.TYPE(rx_packet.type).name))

            if rx_packet.type_sub == DiPacket.TYPE_SUB.RESP_READ_REG_ERROR.value:
                raise RegAccessFailedException("Module returned RESP_READ_REG_ERROR")

            if rx_packet.type_sub != exp_type_sub:
                raise RegAccessFailedException("Expected subtype to be %s, got %s" %
                                               (DiPacket.TYPE_SUB(exp_type_sub).name,
                                                DiPacket.TYPE_SUB(rx_packet.type_sub).name))

            # Extract register value from response
            rx_value = 0
            nr_words = int((word_width / 16))

            if len(rx_packet.payload) != nr_words:
                raise RegAccessFailedException("Expected %d payload words in "
                                               "response, got %d." %
                                               (nr_words, len(rx_packet.payload)))

            for w in range(0, nr_words):
                shift_bit = (nr_words - w - 1) * 16
                rx_value |= rx_packet.payload[w] << shift_bit

            self.dut._log.debug("Successfully read %d bit register 0x%04x from "
                                "module at DI address 0x%04x. Got value 0x%x."
                                % (word_width, regaddr, dest, rx_value))

        except RegAccessFailedException as reg_acc_error:
            dut._log.info(reg_acc_error.message)
            rx_value = None

        raise ReturnValue(rx_value)


    @cocotb.coroutine
    def write_register(self, dest, src, word_width, regaddr,
                       value):
        """
        Write a new value into a register specified by the user and read
        the response to tell the user if the write process was successful

        Args:
            dest:           id of the target module.
            src:            id of the sending module.
            word_width:     choose between 16, 32, 64 and 128 bit register
                            access.
            regaddr:        address of the register the new value will be
                            written to.
            value:          value to write to the register

        """
        tx_packet = DiPacket()
        rx_packet = DiPacket()

        try:
            if word_width == 16:
                type_sub = DiPacket.TYPE_SUB.REQ_WRITE_REG_16.value
                words = 1
            elif word_width == 32:
                type_sub = DiPacket.TYPE_SUB.REQ_WRITE_REG_32.value
                words = 2
            elif word_width == 64:
                type_sub = DiPacket.TYPE_SUB.REQ_WRITE_REG_64.value
                words = 3
            elif word_width == 128:
                type_sub = DiPacket.TYPE_SUB.REQ_WRITE_REG_128.value
                words = 4
            else:
                raise RegAccessFailedException("An invalid register width "
                                               "parameter was chosen!")

            # Assemble payload of REG debug packet
            payload = [regaddr]
            value_words = []
            for w in range(0, words):
                payload.append((value >> ((words - 1 - w) * 16)) & 0xFFFF)

            tx_packet.set_contents(dest=dest, src=src,
                                   type=DiPacket.TYPE.REG.value,
                                   type_sub=type_sub, payload=payload)

            yield self.driver.send_packet(tx_packet)

            rx_packet = yield self.driver.receive_packet()

            if rx_packet.type_sub == DiPacket.TYPE_SUB.RESP_WRITE_REG_ERROR.value:
                raise RegAccessFailedException("An error occurred during the "
                                               "write process!")

            if rx_packet.type_sub != DiPacket.TYPE_SUB.RESP_WRITE_REG_SUCCESS.value:
                raise RegAccessFailedException("Expected subtype to be %s, got %s" %
                                               (DiPacket.TYPE_SUB.RESP_WRITE_REG_SUCCESS.name,
                                                DiPacket.TYPE_SUB(rx_packet.type_sub).name))

            self.dut._log.debug("Successfully wrote %d bit register 0x%04x of module at "
                           "DI address 0x%04x."
                           % (word_width, regaddr, dest))
            success = True

        except RegAccessFailedException as reg_acc_error:
            self.dut._log.info(reg_acc_error.message)
            success = False

        raise ReturnValue(success)

    @cocotb.coroutine
    def assert_reg_value(self, dest, src, regaddr, exp_value):
        """ Assert that a register contains an expected value """

        rx_value = yield self.read_register(dest, src, 16, regaddr)

        if rx_value != exp_value:
            raise TestFailure("Read value 0x%04x from register %x, expected 0x%04x."
                              % (rx_value, regaddr, exp_value))

    @cocotb.coroutine
    def test_base_registers(self, dest, src, values):
        """
        Read the 5 base registers and compare the response with the desired value
        """

        self.dut._log.info("Check contents of MOD_VENDOR")
        yield self.assert_reg_value(dest, src,
                                    DiPacket.BASE_REG.MOD_VENDOR.value,
                                    values[0])

        self.dut._log.info("Check contents of MOD_TYPE")
        yield self.assert_reg_value(dest, src,
                                    DiPacket.BASE_REG.MOD_TYPE.value,
                                    values[1])

        self.dut._log.info("Check contents of MOD_VERSION")
        yield self.assert_reg_value(dest, src,
                                    DiPacket.BASE_REG.MOD_VERSION.value,
                                    values[2])

        self.dut._log.info("Check contents of MOD_CS")
        yield self.assert_reg_value(dest, src,
                                    DiPacket.BASE_REG.MOD_CS.value,
                                    values[3])

        self.dut._log.info("Check contents of MOD_EVENT_DEST")
        yield self.assert_reg_value(dest, src,
                                    DiPacket.BASE_REG.MOD_EVENT_DEST.value,
                                    values[4])
