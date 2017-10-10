import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge

from DiPacket import DiPacket
from NocDriver import NocDriver

class RegAccess:
    """
    Exchange messages on packet level between debug modules
    and read their response
    """

    PACKET_TYPE_REG                          = 0b00
    PACKET_TYPE_PLAIN                        = 0b01
    PACKET_TYPE_EVENT                        = 0b10
    
    PACKET_SUBTYPE_REQ_READ_REG_16           = 0b0000
    PACKET_SUBTYPE_REQ_READ_REG_32           = 0b0001
    PACKET_SUBTYPE_REQ_READ_REG_64           = 0b0010
    PACKET_SUBTYPE_REQ_READ_REG_128          = 0b0011
    PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_16  = 0b1000
    PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_32  = 0b1001
    PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_64  = 0b1010
    PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_128 = 0b1011
    PACKET_SUBTYPE_RESP_READ_REG_ERROR       = 0b1100
    PACKET_SUBTYPE_REQ_WRITE_REG_16          = 0b0100
    PACKET_SUBTYPE_REQ_WRITE_REG_32          = 0b0101
    PACKET_SUBTYPE_REQ_WRITE_REG_64          = 0b0110
    PACKET_SUBTYPE_REQ_WRITE_REG_128         = 0b0111
    PACKET_SUBTYPE_REQ_WRITE_REG_SUCCESS     = 0b1110
    PACKET_SUBTYPE_REQ_WRITE_REG_ERROR       = 0b1111

    @cocotb.coroutine
    def send_packet(self, dut, DiPacket):
        """Takes a debug interconnect packet as its parameter and
           transmits a complete packet to a chosen debug module
        Args:
            dut:            device under test.
            DiPacket:       debug interconnect packet.
        Returns:
            -
        """

        driver = NocDriver()
        flits = DiPacket.get_flits()

        for i in range(0, len(flits)):
            # if the next flit will be the last one
            if i == (len(flits) - 1):
                # indicate this by setting the 'last'-flag
                yield driver.transmit_flit(dut = dut, data = flits[i], last = 1)
            else:
                yield driver.transmit_flit(dut = dut, data = flits[i], last = 0)

        dut.debug_in.valid <= 0

    @cocotb.coroutine
    def receive_packet(self, dut, response):
        """Fills a buffer with incoming data words until the last
           flit of a packed is received
        Args:
            dut:            device under test.
            response:       empty buffer which the incoming flits are stored in.
        Returns:
            response of the debug module of variable length in the
            'response'-buffer
        """

        # get response
        while True:
            # wait for the active clock edge
            yield RisingEdge(dut.clk)

            if dut.debug_out.valid.value:

                # extend the buffer with the debug module's output
                response.append(dut.debug_out.data.value.integer)
                
                # if the last flit has been sent
                if dut.debug_out.last.value:
                    # stop reading in the response 
                    break
                
    @cocotb.coroutine        
    def read_register(self, dut, destination, source, reg_width, address,
                      response):
        """Uses the subroutine 'send_packet' to read a value from
           a specified register and reads the response to tell the user if
           the read process was successful

        Args:
            dut:            device under test.
            destination:    id of the target module.
            source:         id of the sending module.
            reg_width:      choose between 16, 32, 64 and 128 bit register
                            access.
            address:        address of the register the value is to be read
                            from.
            response:       buffer variable which the response of the dut will
                            be stored in

        Returns:
            -

        """

        # branch depending on the width of the accessed data word
        if reg_width == 16:

            subtype = self.PACKET_SUBTYPE_REQ_READ_REG_16
            expected_response = self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_16

        elif reg_width == 32:

            subtype = self.PACKET_SUBTYPE_REQ_READ_REG_32
            expected_response = self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_32

        elif reg_width == 64:

            subtype = self.PACKET_SUBTYPE_REQ_READ_REG_64
            expected_response = self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_64

        elif reg_width == 128:

            subtype = self.PACKET_SUBTYPE_REQ_READ_REG_128
            expected_response = self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_128

        else:
            # display an error if an unsupported register width was chosen
            raise TestFailure("Invalid register width parameter")

        packet = DiPacket(destination = destination, source = source,
                          packet_type = self.PACKET_TYPE_REG,
                          packet_subtype = subtype, payload = address)


        # transmit the read request
        yield self.send_packet(dut = dut, DiPacket = packet)

        # read in the response
        yield self.receive_packet(dut = dut, response = response)
        
        # display the response
        dut._log.info("Answer of the dut:")
        dut._log.info(response)

        # if the module responded with a successful read request, 
        # let the user know
        if ((response[2] & 0x3C00) >> 10) == expected_response:
            dut._log.info("Read process was successful!")

        # if it returned an error, output that error
        elif ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_ERROR:
            dut._log.info("An error occurred during the read process!")

        else:
            dut._log.info("An unidentified error occurred!")


        for _ in range(1):
            yield RisingEdge(dut.clk)

    @cocotb.coroutine
    def write_register(self, dut, destination, source, reg_width, address, 
                       content, response):
        """Uses the subroutine 'send_packet' to write a new value
           into a specified register and reads the response to tell the user
           if the write process was successful

            Args:
            dut:            device under test.
            destination:    id of the target module.
            source:         id of the sending module.
            reg_width:      choose between 16, 32, 64 and 128 bit register
                            access.
            address:        address of the register the new value will be
                            written to.
            content:        value which will be written into the specified
                            register.
            response:       buffer variable which the response of the dut will
                            be stored in.

            Returns:
            -

        """

        # depending on how many data words are to be written into the memory
        if reg_width == 16:

            subtype = self.PACKET_SUBTYPE_REQ_WRITE_REG_16
            words = 1

        elif reg_width == 32:

            subtype = self.PACKET_SUBTYPE_REQ_WRITE_REG_32
            words = 2

        elif reg_width == 64:

            subtype = self.PACKET_SUBTYPE_REQ_WRITE_REG_64
            words = 3

        elif reg_width == 128:

            subtype = self.PACKET_SUBTYPE_REQ_WRITE_REG_128
            words = 4

        else:

            # tell the user that an unsupported register width was chosen
            raise TestFailure("Invalid register width parameter")


        payload = []
        payload.append(address)

        for i in range(0, words):
            # how many times must the 16 bit mask be shifted to the left?
            shift_count = words-(i+1)
            payload.append(((content & (0xFFFF << (16*shift_count)))) >> \
                           (16*shift_count))

        packet = DiPacket(dest = destination, source = source,
                          packet_type = self.PACKET_TYPE_REG,
                          packet_subtype = subtype, payload = payload)


        yield self.send_packet(dut = dut, DiPacket = packet)

        # read the response of the debug module
        response = []
        yield self.receive_packet(dut = dut, response = response)

        # if the module returned a success, everything is fine
        if ((response[2] & 0x3C00) >> 10) == \
        self.PACKET_SUBTYPE_REQ_WRITE_REG_SUCCESS:
            dut._log.info("Write process was successful!")
        # if it returned an error, output that error
        elif ((response[2] & 0x3C00) >> 10) == \
        self.PACKET_SUBTYPE_REQ_WRITE_REG_ERROR:
            dut._log.info("An error occurred during the write process!")
        # otherwise something else went wrong
        else:
            dut._log.info("An unidentified error occurred!")
