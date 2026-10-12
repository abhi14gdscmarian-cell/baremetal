#ifndef MPFS_TEST_E51_MOCK_H
#define MPFS_TEST_E51_MOCK_H

#include <stdint.h>
#include <setjmp.h>

typedef struct
{
    uint32_t clock_config_calls;
    uint32_t clock_peripheral;
    uint32_t clock_hart;
    uint32_t clock_state;
    uint32_t uart_init_calls;
    uintptr_t uart_instance;
    uint32_t uart_baud;
    uint32_t uart_config;
    uint32_t uart_tx_calls;
    uintptr_t uart_tx_instance;
    const uint8_t* uart_tx_string;
} e51_mock_state_t;

extern e51_mock_state_t e51_mock_state;
extern jmp_buf e51_mock_escape;
extern uint32_t e51_mock_escape_after_tx;

void reset_e51_mocks(void);

#endif
