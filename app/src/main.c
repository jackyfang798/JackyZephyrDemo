/*
 * Hello World sample for Zephyr RTOS
 * Target board: STM32 Nucleo L010RB (nucleo_l010rb)
 *
 * Prints "Hello World" to the UART console and then blinks the on-board LED.
 */

#include <zephyr/kernel.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/sys/printk.h>

/* LED0 is the green user LED (LD2) on the Nucleo L010RB */
#define LED0_NODE DT_ALIAS(led0)
static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(LED0_NODE, gpios);

#define SLEEP_TIME_MS 1000

int main(void)
{
    int ret;

    printk("Hello World! Running on %s\n", CONFIG_BOARD);

    if (!gpio_is_ready_dt(&led)) {
        printk("LED device not ready\n");
        return 0;
    }

    ret = gpio_pin_configure_dt(&led, GPIO_OUTPUT_ACTIVE);
    if (ret < 0) {
        printk("Failed to configure LED pin (err %d)\n", ret);
        return 0;
    }

    printk("Blinking LED ...\n");

    while (1) {
        gpio_pin_toggle_dt(&led);
        k_msleep(SLEEP_TIME_MS);
    }

    return 0;
}
