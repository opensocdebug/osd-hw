class DiPacket:
    """
    Represents a complete debug interconnect packet
    """

    def __init__(self, destination, source, packet_type, packet_subtype, 
                 payload):

        self.destination    = destination
        self.source         = source
        self.packet_type    = packet_type
        self.packet_subtype = packet_subtype
        self.payload        = payload

    def get_flits(self):
        """constructs all individual flits of the packet and returns them as 
           a list
            Args:
            -
        Returns:
            list with the individual flits of the packet
        """

        flits = []

        # build the 3 header flits in advance
        flits.append(self.destination)
        flits.append(self.source)
        flits.append(self.packet_type << 14 | self.packet_subtype << 10)

        # number of single messages
        y = len(self.payload)

        if y > 8:
            # output an error if too many flits are to be sent
            raise TestFailure("Number of data words exceeds upper limit!")

        for x in range(0, y):
            # fill in one word after the other
            flits.append(self.payload[x])

        return flits
