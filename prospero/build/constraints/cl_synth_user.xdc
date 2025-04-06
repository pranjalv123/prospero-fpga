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


# Add synthesis constraint here
# AWS F1 build constraints inclusion script

# Load the custom timing constraints file
read_xdc $::env(HDK_DIR)/cl/examples/prospero/build/constraints/timing_constraints.xdc

# Apply XDC constraints
set_property used_in_synthesis true [get_files timing_constraints.xdc]
set_property used_in_implementation true [get_files timing_constraints.xdc]

# Set synthesis strategy for better timing optimization
set_property strategy Performance_Explore [get_runs synth_1]

# Set implementation strategy for better timing optimization
set_property strategy Performance_Explore [get_runs impl_1]

# Additional performance optimization directives
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreArea [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExploreWithRemap [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE MoreGlobalIterations [get_runs impl_1]

# Add the custom source files
add_files -fileset sources_1 -norecurse [list \
  "$::env(HDK_DIR)/cl/examples/prospero/design/pipelined_components.sv" \
  "$::env(HDK_DIR)/cl/examples/prospero/design/circuit_wrapper.sv" \
]

# Force use of slower clock to help with timing
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]

# Additional constraints or build commands can be added below 