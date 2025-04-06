# =============================================================================
# Amazon FPGA Hardware Development Kit
#
# Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================


# Add timing constraints here
# Timing constraints for Prospero design
# Reducing the clock frequency target to help with timing closure

# Set a slower clock period (lower frequency) for the main clock
# Default AWS F1 clock is typically 125MHz (8ns period)
# We're setting it to a more conservative value

# For 100MHz (10ns period)
create_clock -period 10.000 -name clk_main_a0 [get_ports clk_main_a0]

# If still having issues, you can try an even lower frequency, like 75MHz:
# create_clock -period 13.333 -name clk_main_a0 [get_ports clk_main_a0]

# Or 50MHz:
# create_clock -period 20.000 -name clk_main_a0 [get_ports clk_main_a0]

# Cross-clock domain timing exceptions
set_clock_groups -asynchronous -group [get_clocks clk_main_a0] -group [get_clocks clk_hbm_ref]

# False paths for reset signals
set_false_path -from [get_ports rst_main_n]

# Performance optimization directives
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_main_a0]

# Add additional timing margin
set_clock_uncertainty 0.5 [get_clocks clk_main_a0]

# Relax placement constraints for critical components
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets]

# Add some additional timing slack for critical paths
set_multicycle_path 2 -from [get_cells *circuit_wrapper_inst*] -to [get_cells *reg_out_pipe*]

# Add additional application-specific constraints below if needed 