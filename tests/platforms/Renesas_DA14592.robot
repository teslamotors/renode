*** Keywords ***
Create Machine
    [Arguments]                     ${elf}
    Execute Command                 mach create "DA14592"
    Execute Command                 machine LoadPlatformDescription @platforms/cpus/renesas-da14592.repl
    Execute Command                 sysbus LoadELF @${elf} useVirtualAddress=true
    Execute Command                 sysbus.cmac IsHalted true
    Execute Command                 sysbus Tag <0x50000028 +4> "SYS_STAT_REG" 0x605

*** Test Cases ***
UART Should Work
    Create Machine                  https://dl.antmicro.com/projects/renode/renesas-da1459x-hello_world.elf-s_1266192-ec30b009ff7f1c806e6905030626dce2374817db
    Create Terminal Tester          sysbus.uart1

    Wait For Line On Uart           Hello, world!

Test Watchdog
    Create Machine          @https://dl.antmicro.com/projects/renode/renesas_da14592--watchdog.elf-s_1602660-74e8c2cde25d190d225185e9567b6fce4baeeac0

    Execute Command         sysbus.cmac IsHalted true
    Execute Command         sysbus.wdog Enabled false

    Create Log Tester       10
    Execute Command         logLevel -1 sysbus.wdog

    Wait For Log Entry      wdog: Ticker value set to: 0x1FFF
    Execute Command         sysbus.wdog Enabled true

    # The application initializes the wdog and then loops to refresh the watchdog 100 times.
    FOR  ${i}  IN RANGE  101
        Wait For Log Entry      wdog: Ticker value set to: 0x1FFF
    END

    # The application loops waiting for the watchdog to reset the machine.
    Wait For Log Entry      wdog: Limit reached
    Wait For Log Entry      wdog: Triggering IRQ
    Wait For Log Entry      wdog: Limit reached
    Wait For Log Entry      wdog: Reseting machine

Test GPADC
    Create Machine                  https://dl.antmicro.com/projects/renode/renesas_da14592--adc.elf-s_1617224-06ae23b3a2f10598dbec9febef19b9cbee219121
    Execute Command                 sysbus Tag <0x50000028 +4> "SYS_STAT_REG" 0xE0D
    Execute Command                 sysbus Tag <0x50010024 +4> "CLOCK_GENERATION_CONTROLLER2_1" 0x1
    Execute Command                 sysbus.cmac IsHalted true
    Create Terminal Tester          sysbus.uart1
    Execute Command                 sysbus.gpadc FeedSamplesFromRESD @https://dl.antmicro.com/projects/renode/renesas_da14_gpadc.resd-s_49-d7ebebfafe5c44561381ab5c3ffe65266f0a8ad3 6 6

    Wait For Line On Uart           ADC read completed
    Wait For Line On Uart           Number of samples: 21, ADC result value: 18900
