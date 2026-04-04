create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# Checked-in default uses the visible demo clock path in phase_1_synth_top.
# If USE_DEMO_CLOCK is changed to 0 for raw-clock experiments, update this
# internal demo-clock constraint to match that build configuration.
create_clock -name CPU_CLOCK -period 1280.000 \
    [get_nets {board_clock_helper:U_CLOCK|G_DEMO_CLOCK.demo_clock}]
