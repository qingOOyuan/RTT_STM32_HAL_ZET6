/*
 * Copyright (c) 2006-2021, RT-Thread Development Team
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Change Logs:
 * Date           Author       Notes
 * 2018-11-5      SummerGift   first version
 */

#ifndef __BOARD_H__
#define __BOARD_H__

#include <rtthread.h>
#include <stm32f1xx.h>
#include "drv_common.h"
#include "drv_gpio.h"

#ifdef __cplusplus
extern "C" {
#endif

#define STM32_FLASH_START_ADRESS     ((uint32_t)0x08000000)
#define STM32_FLASH_SIZE             (512 * 1024)
#define STM32_FLASH_END_ADDRESS      ((uint32_t)(STM32_FLASH_START_ADRESS + STM32_FLASH_SIZE))

/* Internal SRAM memory size[Kbytes] <8-64>, Default: 64*/
#define STM32_SRAM_SIZE      64
#define STM32_SRAM_END       (0x20000000 + STM32_SRAM_SIZE * 1024)

#if defined(__ARMCC_VERSION)
extern int Image$$RW_IRAM1$$ZI$$Limit;
#define HEAP_BEGIN      ((void *)&Image$$RW_IRAM1$$ZI$$Limit)
#elif __ICCARM__
#pragma section="CSTACK"
#define HEAP_BEGIN      (__segment_end("CSTACK"))
#else
extern int __bss_end;
#define HEAP_BEGIN      ((void *)&__bss_end)
/* Heap size[Kbytes] <8-16>, Default: 16*/
#define STM32_HEAP_SIZE      16
#define STM32_HEAP_END       ((void *)((int)&__bss_end + STM32_HEAP_SIZE * 1024))
#endif

/*
 * The initial address of sp is _estack = STM32_SRAM_END, so the end address of the heap should not be the same here.
 * Otherwise, during the initialization of the heap space, it may conflict with the stack space,
 * resulting in a change in the value of the LR register that has already been saved in the stack,
 * and finally PC returning to an unexpected address. Therefore, a hard fault handle is generated.
 */
// #define HEAP_END        STM32_SRAM_END
#define HEAP_END        STM32_HEAP_END

void SystemClock_Config(void);

#ifdef __cplusplus
}
#endif

#endif /* __BOARD_H__ */
