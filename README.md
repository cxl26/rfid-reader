### Sim/Synth Workflow
1. Enter the TESTBENCH_FILE and TOPLEVEL_FILE filenames in build/makefile.
2. Ensure that constraints and nextpnr part number are set correctly (set for iCEstick by default).
3. Navgiate to build directory.
4. Run _"make sim"_ (to simulate) or _"make synth"_ (to synth and create bitstream).
5. Run _"sudo iceprog bitstream.bin"_ to load bitstream or open _"gtkwave dump.vcd"_ to open waveform.
