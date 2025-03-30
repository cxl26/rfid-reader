### Sim/Synth Workflow
1. Enter the TESTBENCH_FILE and TOPLEVEL_FILE filenames in build/makefile.
2. Ensure that constraints and nextpnr part number are set correctly (set for iCEstick by default).
3. Navgiate to build directory.
4. Run _"make sim"_ (to simulate) or _"make synth"_ (to synth and create bitstream).
5. Run _"sudo iceprog bitstream.bin"_ to load bitstream or open _"gtkwave dump.vcd"_ to open waveform.

### Python MIDI Interface
1. Pip install pynput and pyserial dependencies.
2. Enter the correct USB device name into tools/laptop_midi_interface.py script.
3. Run tools/laptop_midi_interface.py script from command line.
4. Play the middle row of the keyboard like a midi keyboard.

### Python Generate Lookup
1. Ensure that midi_table.csv holds correct pairs of (MIDI Code, Freq in MHz), it already should.
2. Enter DATA_WIDTH, ADDR_WIDTH, CNTR_WIDTH, SAMPLE_FREQUENCY in tools/generate_dds_lookup.py script.
3. Run tools/generate_dds_lookup.py to create the note_lookup.txt and sine_lookup.txt.
4. The RTL in note_lookup.v and sine_lookup.v will $readmemb the values into block ram.