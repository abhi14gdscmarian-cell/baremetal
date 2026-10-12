#include "e51_mock.h"

extern "C" {
#include "drivers/mss/mss_mmuart/mss_uart.h"
#include "inc/uart_mapping.h"
#include "mpfs_hal/mss_hal.h"
}

e51_mock_state_t e51_mock_state;
jmp_buf e51_mock_escape;
uint32_t e51_mock_escape_after_tx;

extern "C" {

static mss_uart_instance_t test_uart;
mss_uart_instance_t* p_uartmap_e51 = &test_uart;
mss_uart_instance_t* p_uartmap_u54_1 = &test_uart;

uint8_t mss_config_clk_rst(uint32_t peripheral, uint8_t hart, uint32_t state)
{
    e51_mock_state.clock_config_calls++;
    e51_mock_state.clock_peripheral = peripheral;
    e51_mock_state.clock_hart = hart;
    e51_mock_state.clock_state = state;
    return 0U;
}

void MSS_UART_init(mss_uart_instance_t* uart, uint32_t baud, uint32_t config)
{
    e51_mock_state.uart_init_calls++;
    e51_mock_state.uart_instance = reinterpret_cast<uintptr_t>(uart);
    e51_mock_state.uart_baud = baud;
    e51_mock_state.uart_config = config;
}

void MSS_UART_polled_tx_string(mss_uart_instance_t* uart, const uint8_t* string)
{
    e51_mock_state.uart_tx_calls++;
    e51_mock_state.uart_tx_instance = reinterpret_cast<uintptr_t>(uart);
    e51_mock_state.uart_tx_string = string;
    if (e51_mock_escape_after_tx != 0U &&
            e51_mock_state.uart_tx_calls >= e51_mock_escape_after_tx)
    {
        longjmp(e51_mock_escape, 1);
    }
}

}

void reset_e51_mocks(void)
{
    e51_mock_state = {};
    e51_mock_escape_after_tx = 0U;
}
