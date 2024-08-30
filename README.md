# Recreate the Versal Project for the Paper

This repository contains the HLD source code required to create the base platform needed for the PPF bank.

## Requirements

The original project was created using Vivado 2023.1. Newer versions will likely work as well, but we do not recommend using older versions. We also recommend first completing the AMD tutorial, which will familiarize you with the tools. We will refer to the tutorial several times since it provides a good overview.
[AMD Tutorial](https://github.com/Xilinx/Vitis-Tutorials/tree/2022.2/AI_Engine_Development/Feature_Tutorials/01-aie_a_to_z)

## Create Base Platform

To create the base platform, we used the example platform from AMD Xilinx and modified it. You can follow this link to the Xilinx tutorial for guidance:
[Custom Base Platform Creation](https://github.com/Xilinx/Vitis-Tutorials/blob/2022.2/AI_Engine_Development/Feature_Tutorials/01-aie_a_to_z/01-custom_base_platform_creation.md)

Afterward, continue with the following steps:
1. Include the PL blocks in your project and drag them into the block design.
2. Connect the traffic generator block to the data alignment block and a constant to its enable.
3. For the data alignment and performance monitor blocks:
   1. Add one AXI GPIO IP instance.
   2. Configure each instance to have two output channels, where the GPIO2 channel is input only.
   3. Connect the `ready_to_read` signal to the input of GPIO.
   4. Connect the `command` signal to the GPIO output.
   5. Connect the `counter_value` signal to the GPIO2 input.
4. Connect each GPIO instance to the AXI smart connect IP.

In the end, your base platform should look something like this:

![Block Design](/pictures/block_design.png)

Next, enable each AXI stream interface of the IP blocks for Vitis inside the Platform tab in Vivado. The SP-Tag is optional but recommended, as it makes it easier to connect later. The convention used here is `DA_OUT` for the data alignment block and `PM_IN` for the performance monitor, numbered starting from zero.

Validate the platform and generate output products.

After this, you can export the platform.

## Create Vitis Project

### Create AIE Application

Create a new platform project using the exported XSA. The Xilinx tutorial can help with this as well. Then, create an AI engine application project on that platform. You can either create an empty project or choose a template and include the source code.

To use the AMD DSP library, the following paths need to be included

The resulting source code directory and include paths should look like this:

![Vitis Include Paths](/pictures/vitis_include.jpeg)

Follow the steps from the tutorial to build for hardware emulation, but use the configuration provided here instead.

Build the platform for hardware emulation.

### Create Host Application

Start again by creating a platform project from the generated XSA. Then, include the `main.cpp` file. Additionally, add the linker script and `aie_control.cpp`. The tutorial also explains how to obtain these files.

Lastly, add some additional settings to the C++ build configuration. Right-click on the application and ensure to add the `__AIE_ARCH__=10` compiler flag. This should look like this:

![Compiler Flags](/pictures/symbols.png)

Afterward, include the DSP library as well. It should look like this:

![Host Include Paths](/pictures/host_include.png)

Now you can build the host application for hardware emulation.

Once this is finished, add the following packaging options to the AIE applications:


"--package.ps_elf ../../<application_name>/Debug/<application_name>.elf,a72-0 --package.defer_aie_run"

Now you can build this application again for hardware.

The created binary can then be uploaded to the VCK190 board using the Vivado hardware manager. The result can be seen over a serial monitor.