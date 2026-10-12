#ifndef MPFS_TEST_MSS_UART_H
#define MPFS_TEST_MSS_UART_H

#include <stdint.h>

typedef struct mss_uart_instance
{
    uint32_t unused;
} mss_uart_instance_t;

#define MSS_UART_115200_BAUD 115200U
#define MSS_UART_DATA_8_BITS 0x01U
#define MSS_UART_NO_PARITY 0x02U
#define MSS_UART_ONE_STOP_BIT 0x04U

void MSS_UART_init(mss_uart_instance_t* uart, uint32_t baud, uint32_t config);
void MSS_UART_polled_tx_string(mss_uart_instance_t* uart, const uint8_t* string);

#endif
