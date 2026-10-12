#ifndef MPFS_TEST_MSS_HAL_H
#define MPFS_TEST_MSS_HAL_H

#include <stdint.h>

#define IMAGE_LOADED_BY_BOOTLOADER 1
#define MSS_PERIPH_MMUART_E51 0U
#define MSS_PERIPH_MMUART_U54_1 1U
#define MPFS_HAL_FIRST_HART 0U
#define PERIPHERAL_ON 1U

uint8_t mss_config_clk_rst(uint32_t peripheral, uint8_t hart, uint32_t state);

#endif
