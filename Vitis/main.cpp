
#include <stdio.h>
#include <stdlib.h>
#include "xil_printf.h"
#include "xil_cache.h"
#include "xil_io.h"
#include "sleep.h"

#include "xparameters.h"
#include "project.cpp"

// these includes need to be made because there are several limitations for using libaries in a bare metal system
#include "fft_twiddle_lut_dit_cfloat.h"
#include "fft_kernel_bufs.h"


#include "xgpio.h"
#define COMMAND_CHANNEL 1
#define DATA_CHANNEL 2

#define COMMAND_BIT_MASK 0x00000001
#define SET_INPUT 1

#define COUNT_CYCLES_GLOBAL 1000000

#define RESET_COMMAND 0x00000040
#define CLEAR_COMMAND 0
#define READ_VALUE_COMMAND 0x0
#define PM_FINISHED 1

#define RECEIVER_STREAMS_128BIT 2

struct AXI_GPIO_STRUCT {
	XGpio_Config *GPIO_Config;
	XGpio GPIO;
	u32 id;

};

struct AXI_GPIO_STRUCT axi_gpio[2];


void GPIO_init(const int gpio_number) {
	int32_t status;
	axi_gpio[gpio_number].GPIO_Config = XGpio_LookupConfig(axi_gpio[gpio_number].id);
	print("Initialize GPIO 0 \r\n");
	status = XGpio_CfgInitialize(&axi_gpio[gpio_number].GPIO, axi_gpio[gpio_number].GPIO_Config, axi_gpio[gpio_number].GPIO_Config->BaseAddress);
	if(status != XST_SUCCESS) {
		print("Error while trying to initialize GPIO \r\n");
	}else {
		print("GPIO initialization successful \r\n");
	}
	XGpio_SetDataDirection(&axi_gpio[gpio_number].GPIO, COMMAND_CHANNEL, COMMAND_BIT_MASK);
	XGpio_SetDataDirection(&axi_gpio[gpio_number].GPIO, DATA_CHANNEL, SET_INPUT);
}


int main() {
	print("Hello there!\r\n");
	uint32_t status;

	


	axi_gpio[0].id = XPAR_AXI_GPIO_0_DEVICE_ID;
	axi_gpio[1].id = XPAR_AXI_GPIO_1_DEVICE_ID;

	for(int i = 0; i < 2 ; i++) {
			GPIO_init(i);
	}

	uint32_t pm_out;
	float percentage;

	printf("AIE Graph Initialization\r\n");
	ppfgraph.init();
	printf("Done \r\n");
	printf("- \r\n");

	ppfgraph.run();
	while(1) {
		print("Reset Array... \r\n");

		pm_out = 0;
		percentage = 0;

		print("Wait for PM 0 to finish. ");
		while(1) {
			status = (XGpio_DiscreteRead(&axi_gpio[0].GPIO, COMMAND_CHANNEL) & COMMAND_BIT_MASK);
			if(status == PM_FINISHED) {
				break;
			}
			sleep(2);
			printf("PM status is: %x ...\r\n", status);
		}

		print("PM0 finished \r\n");

		print("Wait for PM 1 to finish. ");
		while(1) {
			status = (XGpio_DiscreteRead(&axi_gpio[1].GPIO, COMMAND_CHANNEL) & COMMAND_BIT_MASK);
			if(status == PM_FINISHED) {
				break;
			}
			sleep(2);
			printf("PM status is: %x ...\r\n", status);
		}

		print("PM1 finished \r\n");

		print("Read counter value PM 0 ... \r\n");

		XGpio_DiscreteWrite(&axi_gpio[0].GPIO, COMMAND_CHANNEL, READ_VALUE_COMMAND << 1);
		pm_out = XGpio_DiscreteRead(&axi_gpio[0].GPIO, DATA_CHANNEL);
		percentage = ((float)pm_out / COUNT_CYCLES_GLOBAL) * 100;
		printf("Read value is: %u  ", pm_out);
		printf("In percentage of max counts: %f \r\n", percentage);

		print("Read PM 0 finished\r\n");

		print("Read counter value PM 1 ... \r\n");

		for(int i= 0; i < RECEIVER_STREAMS_128BIT; i++) {
			XGpio_DiscreteWrite(&axi_gpio[1].GPIO, COMMAND_CHANNEL, (READ_VALUE_COMMAND + i) << 1);
			pm_out = XGpio_DiscreteRead(&axi_gpio[1].GPIO, DATA_CHANNEL);
			percentage = ((float)pm_out / COUNT_CYCLES_GLOBAL) * 100;
			printf("Read value is: %u  ", pm_out);
			printf("In percentage of max counts: %f \r\n", percentage);
		}
		print("Read PM 1 finished\r\n");

		print("Reset counter \r\n");
		XGpio_DiscreteWrite(&axi_gpio[0].GPIO, COMMAND_CHANNEL, RESET_COMMAND);
		XGpio_DiscreteWrite(&axi_gpio[0].GPIO, COMMAND_CHANNEL, CLEAR_COMMAND);
		XGpio_DiscreteWrite(&axi_gpio[1].GPIO, COMMAND_CHANNEL, RESET_COMMAND);
		XGpio_DiscreteWrite(&axi_gpio[1].GPIO, COMMAND_CHANNEL, CLEAR_COMMAND);

		sleep(4);

		}

    return 0;
}
