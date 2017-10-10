TOPSRCDIR=$(PWD)/../../..
PYTHONPATH:=$(PYTHONPATH):/nas/ei/home/ga94foy/src/hardware/test/cocotb/osdtestlib

VERILOG_SOURCES = \
	$(TOPSRCDIR)/interfaces/common/dii_channel.sv \
	$(PWD)/../common/osd_stm.sv \
	$(TOPSRCDIR)/blocks/regaccess/common/osd_regaccess_layer.sv \
	$(TOPSRCDIR)/blocks/regaccess/common/osd_regaccess.sv \
	$(TOPSRCDIR)/blocks/regaccess/common/osd_regaccess_demux.sv \
	$(TOPSRCDIR)/interconnect/common/ring_router_mux.sv \
	$(TOPSRCDIR)/blocks/timestamp/common/osd_timestamp.sv \
	$(TOPSRCDIR)/./blocks/tracesample/common/osd_tracesample.sv \
	$(TOPSRCDIR)/./blocks/buffer/common/osd_fifo.sv \
	$(TOPSRCDIR)/./blocks/tracepacket/common/osd_trace_packetization.sv
	
TOPLEVEL=osd_stm
MODULE=test_stm
include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

