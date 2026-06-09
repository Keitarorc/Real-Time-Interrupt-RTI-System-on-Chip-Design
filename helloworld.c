//Keitaro Cho
#include <stdio.h>
#include <stdint.h>
#include "platform.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xstatus.h"

#define RTI_BASEADDR        (0x40000000)
#define INTC_DEVICE_ID      XPAR_SCUGIC_SINGLE_DEVICE_ID
#define RTI_INTR_ID         XPS_FPGA0_INT_ID

#define FPGA_REV_REG        0x00
#define SW_RST_REG          0x04
#define RTI_CTRL_REG        0x08
#define INT_CTRL_REG        0x0C
#define INT_STAT_REG        0x10

#define BIT0_MASK           0x00000001
#define BIT1_MASK           0x00000002

static XScuGic IntcInst;
static volatile uint32_t g_interrupt_count = 0;

static inline void RTI_WriteReg(uint32_t offset, uint32_t value)
{
    Xil_Out32(RTI_BASEADDR + offset, value);
}

static inline uint32_t RTI_ReadReg(uint32_t offset)
{
    return Xil_In32(RTI_BASEADDR + offset);
}

static void RTI_EnableRTI(void)
{
    RTI_WriteReg(RTI_CTRL_REG, BIT0_MASK);
}

static void RTI_DisableRTI(void)
{
    RTI_WriteReg(RTI_CTRL_REG, 0x00000000);
}

static void RTI_EnableInterrupt(void)
{
    uint32_t val = RTI_ReadReg(INT_CTRL_REG);
    RTI_WriteReg(INT_CTRL_REG, val | BIT0_MASK);
}

static void RTI_DisableInterrupt(void)
{
    uint32_t val = RTI_ReadReg(INT_CTRL_REG);
    RTI_WriteReg(INT_CTRL_REG, val & ~BIT0_MASK);
}

static void RTI_ClearInterrupt(void)
{
    uint32_t val = RTI_ReadReg(INT_CTRL_REG);
    RTI_WriteReg(INT_CTRL_REG, val | BIT1_MASK);
}

static void RTI_SoftwareReset(void)
{
    RTI_WriteReg(SW_RST_REG, 0x00000000);
}

static void PrintRegisters(void)
{
    xil_printf("[Offset: 0x%02X] FPGA_REV_REG  = 0x%08X\r\n", FPGA_REV_REG,  (uint32_t)RTI_ReadReg(FPGA_REV_REG));
    xil_printf("[Offset: 0x%02X] RTI_CTRL_REG  = 0x%08X\r\n", RTI_CTRL_REG,  (uint32_t)RTI_ReadReg(RTI_CTRL_REG));
    xil_printf("[Offset: 0x%02X] INT_CTRL_REG  = 0x%08X\r\n", INT_CTRL_REG,  (uint32_t)RTI_ReadReg(INT_CTRL_REG));
    xil_printf("[Offset: 0x%02X] INT_STAT_REG  = 0x%08X\r\n", INT_STAT_REG,  (uint32_t)RTI_ReadReg(INT_STAT_REG));
}

static void RTI_Isr(void *CallbackRef)
{
    (void)CallbackRef;

    g_interrupt_count++;

    xil_printf("ISR: RTI interrupt received. Count = %d\r\n", g_interrupt_count);
    xil_printf("[Offset: 0x%02X] INT_STAT_REG = 0x%08X\r\n", INT_STAT_REG, (uint32_t)RTI_ReadReg(INT_STAT_REG));

    RTI_ClearInterrupt();

    xil_printf("ISR: Interrupt clear command issued.\r\n");
    xil_printf("[Offset: 0x%02X] INT_STAT_REG = 0x%08X\r\n\n", INT_STAT_REG, (uint32_t)RTI_ReadReg(INT_STAT_REG));
}

static int SetupInterruptSystem(XScuGic *IntcInstancePtr)
{
    int status;
    XScuGic_Config *IntcConfig;

    IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (IntcConfig == NULL)
    {
        return XST_FAILURE;
    }

    status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    XScuGic_SetPriorityTriggerType(IntcInstancePtr, RTI_INTR_ID, 0xA0, 0x3);

    status = XScuGic_Connect(IntcInstancePtr, RTI_INTR_ID, (Xil_InterruptHandler)RTI_Isr, NULL);
    if (status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    XScuGic_Enable(IntcInstancePtr, RTI_INTR_ID);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, IntcInstancePtr);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

int main(void)
{
    int status;
    char cmd;

    init_platform();

    xil_printf("Start of RTI Interrupt Generator Test\r\n\n");
    xil_printf("Base Address: 0x%08X\r\n", (uint32_t)RTI_BASEADDR);
    xil_printf("Interrupt ID: %d\r\n", (uint32_t)RTI_INTR_ID);

    status = SetupInterruptSystem(&IntcInst);
    if (status != XST_SUCCESS)
    {
        xil_printf("ERROR: Interrupt setup failed\r\n");
        cleanup_platform();
        return -1;
    }

    xil_printf("GIC setup complete\r\n\n");

    PrintRegisters();
    PrintMenu();

    while(1)
    {
        xil_printf("Enter command: ");

        do
        {
            cmd = inbyte();
        } while ((cmd == '\r') || (cmd == '\n'));
        xil_printf("%c\r\n", cmd);

        switch(cmd)
        {
            case '1':
            {
                xil_printf("Enabling RTI\n");
                RTI_EnableRTI();
                xil_printf("[Offset: 0x%02X] RTI_CTRL_REG = 0x%08X\r\n\n", RTI_CTRL_REG, (uint32_t)RTI_ReadReg(RTI_CTRL_REG));
                break;
            }

            case '2':
            {
                xil_printf("Disabling RTI\n");
                RTI_DisableRTI();
                xil_printf("[Offset: 0x%02X] RTI_CTRL_REG = 0x%08X\r\n\n", RTI_CTRL_REG, (uint32_t)RTI_ReadReg(RTI_CTRL_REG));
                break;
            }

            case '3':
            {
                xil_printf("Enabling interrupt\n");
                RTI_EnableInterrupt();
                xil_printf("[Offset: 0x%02X] INT_CTRL_REG = 0x%08X\r\n\n", INT_CTRL_REG, (uint32_t)RTI_ReadReg(INT_CTRL_REG));
                break;
            }

            case '4':
            {
                xil_printf("Disabling interrupt...\r\n");
                RTI_DisableInterrupt();
                xil_printf("[Offset: 0x%02X] INT_CTRL_REG = 0x%08X\r\n\n", INT_CTRL_REG, (uint32_t)RTI_ReadReg(INT_CTRL_REG));
                break;
            }

            case '5':
            {
                xil_printf("Clearing interrupt...\r\n");
                RTI_ClearInterrupt();
                xil_printf("[Offset: 0x%02X] INT_STAT_REG = 0x%08X\r\n\n", INT_STAT_REG, (uint32_t)RTI_ReadReg(INT_STAT_REG));
                break;
            }

            case '6':
            {
                xil_printf("Performing software reset...\r\n");
                RTI_SoftwareReset();
                xil_printf("Software reset complete.\r\n\n");
                PrintRegisters();
                break;
            }

            case '7':
            {
                PrintRegisters();
                xil_printf("Interrupt Count = %d\r\n\n", g_interrupt_count);
                break;
            }

            case '8':
            {
                g_interrupt_count = 0;
                xil_printf("Interrupt Count cleared.\r\n\n");
                break;
            }

            case 'h':
            {
				xil_printf("RTI Interrupt GenMenu\r\n");
				xil_printf("--------------------------------------------------\r\n");
				xil_printf("1. Enable RTI\n");
				xil_printf("2. Disable RTI\n");
				xil_printf("3. Enable interrupt\n");
				xil_printf("4. Disable interrupt\n");
				xil_printf("5. Clear interrupt\n");
				xil_printf("6. Software reset\n");
				xil_printf("7. Read registers\n");
				xil_printf("8. Clear interrupt count\n");
				xil_printf("h. Display menu\n");
				xil_printf("--------------------------------------------------\r\n\n");
                break;
            }

            default:
            {
                xil_printf("Invalid command.\r\n\n");
            }
        }
    }
    return 0;
}
