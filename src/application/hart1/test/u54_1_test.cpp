#include <cstring>
#include <gtest/gtest.h>
#include "e51_mock.h"

extern "C" {
#include "../u54_1.c"
}

TEST(U54_1Test, ConfiguresItsUartAndPrintsStartupBanner)
{
    reset_e51_mocks();

    if (setjmp(e51_mock_escape) == 0)
    {
        e51_mock_escape_after_tx = 1U;
        u54_1();
        FAIL() << "u54_1() returned without transmitting its startup banner";
    }

    e51_mock_escape_after_tx = 0U;

    EXPECT_EQ(e51_mock_state.clock_config_calls, 1U);
    EXPECT_EQ(e51_mock_state.clock_peripheral, MSS_PERIPH_MMUART_U54_1);
    EXPECT_EQ(e51_mock_state.clock_hart, 1U);
    EXPECT_EQ(e51_mock_state.clock_state, PERIPHERAL_ON);

    EXPECT_EQ(e51_mock_state.uart_init_calls, 1U);
    EXPECT_EQ(e51_mock_state.uart_instance, reinterpret_cast<uintptr_t>(p_uartmap_u54_1));
    EXPECT_EQ(e51_mock_state.uart_baud, MSS_UART_115200_BAUD);
    EXPECT_EQ(
        e51_mock_state.uart_config,
        MSS_UART_DATA_8_BITS | MSS_UART_NO_PARITY | MSS_UART_ONE_STOP_BIT);

    EXPECT_EQ(e51_mock_state.uart_tx_calls, 1U);
    EXPECT_EQ(e51_mock_state.uart_tx_instance, reinterpret_cast<uintptr_t>(p_uartmap_u54_1));
    ASSERT_NE(e51_mock_state.uart_tx_string, nullptr);
    EXPECT_NE(std::strstr(
        reinterpret_cast<const char*>(e51_mock_state.uart_tx_string),
        "U54_1 core is up"), nullptr);
}

TEST(U54_1Test, SoftwareInterruptHandlerIncrementsCounter)
{
    count_sw_ints_h1 = 0U;

    Software_h1_IRQHandler();

    EXPECT_EQ(count_sw_ints_h1, 1U);
}
