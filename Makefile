
# $@--目标文件，$^--所有的依赖文件，$<--第一个依赖文件。

######################################
# target
######################################
TARGET = lucky


######################################
# building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -O2
# 显示命令
#Q		:= @

#######################################
# paths
#######################################
# Build path
BUILD_DIR = Output

#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-
GCC_PATH =

# The gcc compiler bin path can be either defined in make command via GCC_PATH variable (> make GCC_PATH=xxx)
# either it can be added to the PATH environment variable.
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
GDB = $(GCC_PATH)/$(PREFIX)gdb
ASM = $(GCC_PATH)/$(PREFIX)objdump
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
GDB = $(PREFIX)gdb
ASM = $(PREFIX)objdump
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m3

# fpu
# NONE for Cortex-M0/M0+/M3

# float-abi

# mcu
MCU = $(CPU) -mthumb

# macros for gcc
# AS defines
AS_DEFS =

# C defines
C_DEFS = -DUSE_HAL_DRIVER -DSTM32F103xE

# link script
LDSCRIPT = Libraries/CMSIS/Scr/STM32F103ZETx_FLASH.ld


# C sources
C_SOURCES := $(shell find ./ -name '*.c')

# ASM sources
ASM_SOURCES = \
Libraries/CMSIS/Scr/startup_stm32f103xe.s \
CPU/cortex-m3/context_gcc.s

# AS includes
AS_INCLUDES =

# C includes

#C_INCLUDES := $(shell find ./ -name '*.h')

C_INCLUDES = -IApplications                 \
-IDeviceDrivers/include	                    \
-IDrivers                                   \
-IDrivers/f1                                \
-IFinsh                                     \
-IKernel/include                            \
-ILibraries/CMSIS/Inc/common                \
-ILibraries/CMSIS/Inc/Device                \
-ILibraries/HAL_Config/Inc                  \
-ILibraries/STM32F1xx_HAL_Driver/Inc        \
-ILibraries/STM32F1xx_HAL_Driver/Inc/Legacy


# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif

# Generate dependency information
# 添加了依赖信息标志，用于生成依赖文件，这样当头文件改变时，相关的源文件会重新编译。
CFLAGS += -MMD -MP -MF "$(@:%.o=%.d)"

# libraries
LIBS = -lc -lm -lnosys
LIBDIR =
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(TARGET).map,--cref -Wl,--gc-sections
#nona.specs 将 -lc 替换成 -lc_nano，即：使有精简版的C库替代标准C库。
#精简的C库有些特性是被排除掉的，比如 printf* 系列函数不支持浮点数的格式化，因为做了精简，
#因此最终生成的程序映像要比使用标准C库要小一些。如果没有用到这部分特性，就可以通过 -specs=nano.specs 节约有限的代码空间，
#如果使用了该参数后发现有些C库函数行为不符合预期，比如 sprintf 没有格式化浮点数，那么将这个参数去掉。

#GCC 在编译时可以使用 -ffunction-sections 和 -fdata-sections 将每个函数或符号创建为一个 sections，
#其中每个 sections 名与 function 或 data 名保持一致。而在链接阶段，
#-Wl,–gc-sections 指示链接器去掉不用的section（其中-wl, 表示后面的参数 -gc-sections 传递给链接器），
#这样就能减少最终的可执行程序的大小了。


# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(TARGET).hex $(TARGET).bin

#######################################
# build the application
#######################################
# list of ASM program objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES))) #在ASM_SOURCES中寻找.s文件

# list of c objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) # ‘|’ 当build_dir不存在时会创建
	$(Q)$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

# 当代码很多元编程不好阅读的时候，可以手动展开，也可以直接在Makefile中用预处理展开
#	$(Q)$(CC) -E $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $(basename $@).i

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(Q)$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(Q)$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

%.hex: $(BUILD_DIR)/%.elf
	$(HEX) $< $@

%.bin: $(BUILD_DIR)/%.elf
	$(BIN) $< $@

$(BUILD_DIR):
	mkdir $@

dasm:
	$(ASM) -d $(BUILD_DIR)/$(TARGET).elf > $(TARGET).s

clean:
	-rm -fR $(BUILD_DIR)
	-rm -f $(TARGET).hex
	-rm -f $(TARGET).bin
	-rm -f $(TARGET).s
	-rm -f $(TARGET).map

flash:
	@echo "Downloading..."
	openocd -f "tools/openocd.cfg" \
	-c init \
	-c reset \
	-c halt \
	-c "flash write_image erase $(TARGET).hex" \
	-c reset -c shutdown

debug:
	@echo "Waiting for GDB connection..."
	openocd -f "tools/openocd.cfg" \
	-c "gdb_port 3333" \
	-c "telnet_port 4444" \
	-c "init" \
	-c "reset" \
	-c "halt" \
	-c "arm semihosting enable"

# dependencies
-include $(wildcard $(BUILD_DIR)/*.d)

