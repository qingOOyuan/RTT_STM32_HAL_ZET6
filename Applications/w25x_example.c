#include <rtthread.h>
#include <rtdevice.h>
#include <board.h>

#define W25Q_SPI_DEVICE_NAME     "spi20"
#define CS_PORT                   GPIOB
#define CS_GPIO                   GPIO_PIN_12

static rt_uint32_t spi_w25q_sample(int argc, char *argv[])
{
    struct rt_spi_device *spi_w25q_device;
    struct rt_spi_configuration spi2_cfg;

    rt_uint8_t w25q_read_id_cmd[4] = {0x90, 0x00, 0x00, 0x00};
    rt_uint8_t w25q_id[2] = {0};
    rt_uint8_t ret = 0;

    /* 1. attach a device on SPI bus */
    rt_hw_spi_device_attach("spi2", W25Q_SPI_DEVICE_NAME, CS_PORT, CS_GPIO);
    if(ret != RT_EOK) {
        /* not found the host bus */
        rt_kprintf("rt_spi_bus_attach_device fail...\n");
        return -RT_ERROR;
    }

    /* 2. find spi device on SPI bus */
    spi_w25q_device = (struct rt_spi_device *)rt_device_find(W25Q_SPI_DEVICE_NAME);
    if(spi_w25q_device == RT_NULL) {
        /* not found the SPI device */
        rt_kprintf("rt_device_find fail...\n");
        return -RT_ERROR;
    }

    /* 3. config spi bus */
    spi2_cfg.data_width = 8;
    spi2_cfg.mode = RT_SPI_MASTER | RT_SPI_MODE_0 | RT_SPI_MSB;
    spi2_cfg.max_hz = 20 * 1000 * 1000;               /* 20M */
    rt_spi_configure(spi_w25q_device, &spi2_cfg);

    /* 4. read spi flash ID */
/****************************************** Usage one ************************************************/

    rt_spi_send_then_recv(spi_w25q_device, w25q_read_id_cmd, 4, w25q_id, 2);
    rt_kprintf("read w25x ID is: %x%x\n", w25q_id[0], w25q_id[1]);

/****************************************** Usage two ************************************************/
#if 0
    struct rt_spi_message msg1, msg2;

    msg1.send_buf   = w25q_read_id_cmd;
    msg1.recv_buf   = RT_NULL;
    msg1.length     = 4;
    msg1.cs_take    = 1;
    msg1.cs_release = 0;
    msg1.next       = &msg2;

    msg2.send_buf   = RT_NULL;
    msg2.recv_buf   = w25q_id;
    msg2.length     = 2;
    msg2.cs_take    = 1;
    msg2.cs_release = 1;
    msg2.next       = RT_NULL;

    rt_spi_transfer_message(spi_w25q_device, &msg1);
    rt_kprintf("read w25q ID is: %x%x\n", w25q_id[0], w25q_id[1]);
#endif
/*****************************************************************************************************/
    return RT_EOK;
}

/* export to msh cmd list */
MSH_CMD_EXPORT(spi_w25q_sample, spi w25q sample);
