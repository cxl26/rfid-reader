.PHONY: synth sim clean pysim

# TESTBENCH_FILE = ../tests/sync_fifo_tb.v
# TOPLEVEL_FILE  = ../source/fifo/sync_fifo.v

TESTBENCH_FILE = ../tests/preamble_detector_tb.v
TOPLEVEL_FILE  = ../source/detect_preamble/preamble_detector.v

synth:
	yosys \
		-l ../logs/yosys_log.txt \
		-p "read_verilog $(TOPLEVEL_FILE);  hierarchy \
		-libdir ../source/clk  \
		-libdir ../source/dds  \
		-libdir ../source/effects  \
		-libdir ../source/fifo \
		-libdir ../source/ram  \
		-libdir ../source/uart\
		-libdir ../source/detect_preamble;\
		-libdir ../source/detect_bits;\
		-libdir ../source/encode;\
		synth_ice40 -noflatten; \
		write_blif rfid-reader.blif; \
		write_json rfid-reader.json;"
	nextpnr-ice40 -l ../logs/nextpnr_log.txt --hx1k --package tq144 --json rfid-reader.json --pcf constraint.pcf --asc rfid-reader.asc
	# icetime -p constraint.pcf -P tq144 -d hx1k -t rfid-reader.asc -r ../logs/icetime_log.txt
	# icepack rfid-reader.asc bitstream.bin

sim:
	iverilog \
		-o rfid-reader.out -g2012 \
		-Y .v \
		-y ../source/clk  \
		-y ../source/dds  \
		-y ../source/effects  \
		-y ../source/fifo \
		-y ../source/ram  \
		-y ../source/uart \
		-y ../source/detect_preamble \
		-y ../source/detect_bits \
		-y ../source/encode \
		-y ../source      \
		-l ../source/cells_sim.v \
		$(TESTBENCH_FILE)
	vvp -l ../logs/iverilog_log.txt rfid-reader.out

clean:
	rm -f *.json *.blif *.asc *.bin
	rm -f *.out *.vcd