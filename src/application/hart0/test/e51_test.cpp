#include <gtest/gtest.h>
#include "e51_mock.h"

extern "C" {
#include "../e51.c"
}

TEST(E51Test, InitializesAndRepeatsBannerAtTheConfiguredInterval)
{
    reset_e51_mocks();

    if (setjmp(e51_mock_escape) == 0)
    {
        /* The first TX is the startup banner; escape on the periodic banner. */
        e51_mock_escape_after_tx = 2U;
        e51();
        FAIL() << "e51() returned without reaching the periodic UART message";
    }

    e51_mock_escape_after_tx = 0U;

    EXPECT_EQ(e51_mock_state.clock_config_calls, 1U);
    EXPECT_EQ(e51_mock_state.uart_init_calls, 1U);
    EXPECT_EQ(e51_mock_state.uart_tx_calls, 2U);
}

TEST(E51Test, SoftwareInterruptHandlerIncrementsCounter)
{
    count_sw_ints_h0 = 0U;

    Software_h0_IRQHandler();

    EXPECT_EQ(count_sw_ints_h0, 1U);
}
