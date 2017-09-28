import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
from cocotb.triggers import RisingEdge

class NoC_Driver:
    """
    Class responsible for delivering individual words to a debug module and 
    processing their reaction
    """

    @cocotb.coroutine
    def build_flit(self, dut, data, last):
        """function which transmits one flit between debug modules
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

            
    @cocotb.coroutine    
    def init(self, dut, ID):
        """function which initializes the testbench by setting up the clock, 
           resetting the device under test and assigning an ID to it
            
            Args:
            dut:            device under test.
            ID:             module address which is assigned to the dut.
            
            Returns:
            -
        
        """
    
        # setup clock
        cocotb.fork(Clock(dut.clk, 1000).start())
    
        # reset
        dut._log.info("Resetting DUT")
        dut.rst <= 1

        dut.trace_valid <= 1
        dut.debug_out_ready <= 1
        dut.debug_in.valid <= 1
    
        # set module address to the second function parameter
        dut.id <= ID

        for _ in range(2):
            yield RisingEdge(dut.clk)
        dut.rst <= 0
    
    
class Reg_Access:
    """
    Class responsible for exchanging messages between debug modules and reading 
    in their response
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
    def send_packet(self, dut, packet_driver, packet_utility, destination,
                    source, packet_type, packet_subtype, message):
        """function which takes necessary information as its arguments and 
           transmits a complete packet to a chosen debug module
        Args:
            dut:            device under test.
            destination:    id of the module which is the destination.
            source:         id of the module which is the source.
            packet_type:    possible values are: PACKET_TYPE_REG,
                            PACKET_TYPE_PLAIN and PACKET_TYPE_EVENT.
            packet_subtype: choose from one of the const values: read or write 
                            requests of variable length as well as read/write 
                            responses(success/error).
            message:        a payload of variable length (up to 8 16 bit words)
        Returns:
            -
        """
        
        # build the 3 header flits in advance
        dest = packet_utility.constructheader1(destination = destination)
        sour = packet_utility.constructheader2(source = source)
        type = packet_utility.constructheader3(packet_type = packet_type, 
                                               packet_subtype = packet_subtype)
        
        # transmit the 3 header flits
        yield packet_driver.build_flit(dut = dut, data = dest, last = 0)
        yield packet_driver.build_flit(dut = dut, data = sour, last = 0)
        yield packet_driver.build_flit(dut = dut, data = type, last = 0)
        
        # number of single messages
        y = len(message)
        
        if y > 8:
            # output an error if too many flits are to be sent
            raise TestFailure("Number of data words exceeds upper limit!")
        
        for x in range(0, y):
            # extract one word after the other
            newmessage = message[x]
            
            # determine if the last flit has to be sent
            if x == (y-1):
                # indicate this by setting the 'last'-bit
                yield packet_driver.build_flit(dut = dut, data = newmessage, 
                                               last = 1)
            else:
                yield packet_driver.build_flit(dut = dut, data = newmessage, 
                                               last = 0)
        dut.debug_in.valid <= 0
        
    @cocotb.coroutine
    def receive_packet(self, dut, response):
        """successively fills a buffer with incoming data words until the last 
           flit of a packed is received
        Args:
            dut:            device under test.
            response:       (preferably) empty buffer which the incoming flits
                            are stored in.
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
    def RegRead(self, dut, read_driver, read_utility, destination, source, 
                reg_width, address, response):
        """function which uses the subroutine 'send_packet' to read a value from
           a specified register and reads in the response to tell the user if 
           the read process was successful
            
        Args:
            dut:            device under test.
            destination:    id of the module which is the destination.
            source:         id of the module which is the source.
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
            # transmit the read request
            yield self.send_packet(dut = dut, packet_driver = read_driver, 
                                   packet_utility = read_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_READ_REG_16, 
                                   message = address)
            
            # read in the response
            yield self.receive_packet(dut = dut, response = response)
            
            # print the response of the dut
            dut._log.info("Answer of the dut:")
            dut._log.info(response)
            
            # if the module returned a success, everything is fine
            if ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_16:
                dut._log.info("Read process was successful!")
            # if it returned an error, output that error
            elif ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_ERROR:
                dut._log.info("An error occurred during the read process!")
            # otherwise something else went wrong
            else:
                dut._log.info("An unidentified error occurred!")
                
        elif reg_width == 32:
            # transmit the read request
            yield self.send_packet(dut = dut, packet_driver = read_driver, 
                                   packet_utility = read_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_READ_REG_32,
                                   message = address)
            
            # read in the response
            yield self.receive_packet(dut = dut, response = response)
            
            # print the response of the dut
            dut._log.info("Answer of the dut:")
            dut._log.info(response)
            
            # if the module returned a success, everything is fine
            if ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_32:
                dut._log.info("Read process was successful!")
            # if it returned an error, output that error
            elif ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_ERROR:
                dut._log.info("An error occurred during the read process!")
            # otherwise something else went wrong
            else:
                dut._log.info("An unidentified error occurred!")
                
        elif reg_width == 64:
            # transmit the read request
            yield self.send_packet(dut = dut, packet_driver = read_driver, 
                                   packet_utility = read_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_READ_REG_64, 
                                   message = address)
            
            # read in the response
            yield self.receive_packet(dut = dut, response = response)
            
            # print the response of the dut
            dut._log.info("Answer of the dut:")
            dut._log.info(response)
            
            # if the module returned a success, everything is fine
            if ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_64:
                dut._log.info("Read process was successful!")
            # if it returned an error, output that error
            elif ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_ERROR:
                dut._log.info("An error occurred during the read process!")
            # otherwise something else went wrong
            else:
                dut._log.info("An unidentified error occurred!")
                
        elif reg_width == 128:
            # transmit the read request
            yield self.send_packet(dut = dut, packet_driver = read_driver, 
                                   packet_utility = read_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_READ_REG_128, 
                                   message = address)
            
            # read in the response
            yield self.receive_packet(dut = dut, response = response)
            
            # print the response of the dut
            dut._log.info("Answer of the dut:")
            dut._log.info(response)
            
            # if the module returned a success, everything is fine
            if ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_SUCCESS_128:
                dut._log.info("Read process was successful!")
            # if it returned an error, output that error
            elif ((response[2] & 0x3C00) >> 10) == \
            self.PACKET_SUBTYPE_RESP_READ_REG_ERROR:
                dut._log.info("An error occurred during the read process!")
            # otherwise something else went wrong
            else:
                dut._log.info("An unidentified error occurred!")
                
        else:
            # display an error message if an unsupported register width was 
            # chosen
            raise TestFailure("Invalid register width parameter")
        
        for _ in range(1):
            yield RisingEdge(dut.clk)
            
    @cocotb.coroutine        
    def RegWrite(self, dut, write_driver, write_utility, destination, source, 
                 reg_width, address, content, response):
        """function which uses the subroutine 'send_packet' to write a new value 
           into a specified register and reads in the response to tell the user 
           if the write process was successful
            
            Args:
            dut:            device under test.
            destination:    id of the module which is the destination.
            source:         id of the module which is the source.
            reg_width:      choose between 16, 32, 64 and 128 bit register 
                            access.
            address:        address of the register the new value will be 
                            written to.
            content:        value which will be written to the specified 
                            register
            response:       buffer variable which the response of the dut will 
                            be stored in
            
            Returns:
            -
            
        """
        
        # depending on how many data words are to be written into the memory
        if reg_width == 16:
            # send a write request to the dut
            yield self.send_packet(dut = dut, packet_driver = write_driver, 
                                   packet_utility = write_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_WRITE_REG_16, 
                                   message = content)
        elif reg_width == 32:
            # send a write request to the dut
            yield self.send_packet(dut = dut, packet_driver = write_driver, 
                                   packet_utility = write_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_WRITE_REG_32, 
                                   message = content)
        elif reg_width == 64:
            # send a write request to the dut
            yield self.send_packet(dut = dut, packet_driver = write_driver, 
                                   packet_utility = write_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_WRITE_REG_64, 
                                   message = content)
        elif reg_width == 128:
            # send a write request to the dut
            yield self.send_packet(dut = dut, packet_driver = write_driver, 
                                   packet_utility = write_utility, 
                                   destination = destination, source = source, 
                                   packet_type = self.PACKET_TYPE_REG, 
                                   packet_subtype = \
                                   self.PACKET_SUBTYPE_REQ_WRITE_REG_128, 
                                   message = content)
        else:
            # tell the user that an unsupported register width was chosen
            raise TestFailure("Invalid register width parameter")
        
        # read in the response of the debug module
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
                
class Utility:
    """
    Class providing additional methods used by instances of other classes
    """
    
    BASE_REG_TEST = 0
    
    def constructheader1(self, destination):
        """function which returns a data word which can later on be used for the 
           transmission of the first packet header
            
            Args:
            destination:    id of the module which is the destination.
            
            Returns:
                            16 bit word containing the information which will be 
                            transmitted by the first packet header.
         
        """
        
        return 0x0000 | (destination & 0xFFF)
        
        
    def constructheader2(self, source):
        """function which returns a data word which can later on be used for the 
           transmission of the second packet header
            
             Args:
            source:         id of the module which is the source.
        
            Returns:
                            16 bit word containing the information which will be 
                            transmitted by the second packet header.
        
        """
        
        return 0x0000 | (source & 0xFFFF)
        
        
    def constructheader3(self, packet_type, packet_subtype):
        """function which returns a data word which can later on be used for the 
           transmission of the third packet header
            
            Args:
            packet_type:    possible values are: PACKET_TYPE_REG,
                            PACKET_TYPE_PLAIN 
                            and PACKET_TYPE_EVENT.
            packet_subtype: choose from one of the const values: read or write 
                            requests of variable length as well as read/write 
                            responses(success/error).
            
            Returns:
                            16 bit word containing the type of the data request 
                            for a packet.
            
        """

        return 0x0000 | ((packet_type & 0x03) << 14) | \
            ((packet_subtype & 0x0F) << 10)
    
    @cocotb.coroutine
    def evaluate_packet(self, dut, response, destination, source, width, 
                        expectedPL):
        """compares a received packet with its expectation values and outputs 
           the result in the console
        Args:
            dut:            device under test.
            response:       read in response of the debug module.
            destination:    id of the module which initially was the 
                            destination.
            source:         id of the module which initially was the source.
            width:          data width of the register the data was read from/
                            written to.
            expectedPL:     expected received payload.
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

                for x in range(0, (width/16)):
                    # step through the individual payload flits
                    if response[3 + x] != expectedPL[x]:
                        # test failed if a flit has the wrong value
                        raise TestFailure("Expected payload word %d to be 0x%x,\
                         got 0x%x" % 
                                          (x, expectedPL[x], response[3 + x]))
                        result = 0
                        
        if result:
            # test was successful if none of the above mentioned errors occurred
            dut._log.info("Passed the test!")
            
            # clear the buffer for the next RegRead()
            del response[:]
            
        for _ in range(1):
            yield RisingEdge(dut.clk)
            
            
    @cocotb.coroutine        
    def ModuleSubTest_STM(self, dut, test_driver, test_access, test_id):
        """function which takes a second parameter aside from the device under 
           test to specify which functionality of the debug module should be 
           tested and which tells the user if the correct values are stored 
           inside the base registers of a debug module
           
            Args:
            dut:            device under test.
            test_id:        ID indicating which functionality should be tested.
            
            Returns:
            -
            
        """
        
        # other tests could potentially be added
        if test_id == self.BASE_REG_TEST:
            
            response = []
            
            #========================================================Test MOD_ID
            
            # specify how the result should look like
            expected_payload = []
            expected_payload.append(1)
            
            # specify which register to read from
            address = []
            address.append(0)
            
            # read out the register
            yield test_access.RegRead(dut = dut, read_driver = test_driver, 
                                      read_utility = self, destination = 1, 
                                      source = 0, reg_width = 16, 
                                      address = address, response = response)
    
            yield self.evaluate_packet(dut = dut, response = response, 
                                       destination = 1, source = 0, width = 16, 
                                       expectedPL = expected_payload)
            
            #===================================================Test MOD_VERSION
            
            # specify how the result should look like
            expected_payload = []
            expected_payload.append(4)
            
            # specify which register to read from
            address = []
            address.append(1)
            
            # read out the register
            yield test_access.RegRead(dut = dut, read_driver = test_driver, 
                                      read_utility = self, destination = 1, 
                                      source = 0, reg_width = 16, 
                                      address = address, response = response)
            
            yield self.evaluate_packet(dut = dut, response = response, 
                                       destination = 1, source = 0, width = 16,
                                       expectedPL = expected_payload)    
                
            #====================================================Test MOD_VENDOR
            
            # specify how the result should look like
            expected_payload = []
            expected_payload.append(0)
            
            # specify which register to read from
            address = []
            address.append(2)
            
            # read out the register
            yield test_access.RegRead(dut = dut, read_driver = test_driver, 
                                      read_utility = self, destination = 1, 
                                      source = 0, reg_width = 16, 
                                      address = address, response = response)
            
            yield self.evaluate_packet(dut = dut, response = response, 
                                       destination = 1, source = 0, width = 16,
                                       expectedPL = expected_payload)
                    
            #========================================================Test MOD_CS
            #
            # expected_payload = []
            # expected_payload.append(1)
            #
            # address = []
            # address.append(3)
            #
            # yield test_access.RegRead(dut = dut, read_driver = test_driver, 
            #                           read_utility = self, destination = 1, 
            #                           source = 0, reg_width = 16, 
            #                           address = address, response = response)
            #
            # yield self.evaluate_packet(dut = dut, response = response, 
            #                            destination = 1, source = 0, 
            #                            width = 16, 
            #                            expectedPL = expected_payload)
            #
            #================================================Test MOD_EVENT_DEST
            #
            # expected_payload = []
            # expected_payload.append(1)
            #
            # address = []
            # address.append(4)
            #
            # yield test_access.RegRead(dut = dut, read_driver = test_driver, 
            #                           read_utility = self, destination = 1, 
            #                           source = 0, reg_width = 16, 
            #                           address = address, response = response)
            #
            # yield self.evaluate_packet(dut = dut, response = response, 
            #                            destination = 1, source = 0, 
            #                            width = 16, 
            #                            expectedPL = expected_payload)
            #===================================================================
            
            for _ in range(1):
                yield RisingEdge(dut.clk)