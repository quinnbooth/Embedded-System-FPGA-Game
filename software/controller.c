#include "controller.h"
#include <libusb-1.0/libusb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct controller_list open_controllers() {

        printf("Searching for USB connections...\n");

        uint8_t endpoint_address = 0;
        struct controller_list devices;
        libusb_device **devs;
        struct libusb_device_descriptor desc;
        struct libusb_device_handle *controller = NULL;
        ssize_t num_devs;


        // Boot libusb library
        if (libusb_init(NULL) != 0) {
                printf("\nERROR: libusb failed to boot");
                exit(1);
        }

        if  ((num_devs = libusb_get_device_list(NULL, &devs)) < 0) {
                printf("\nERROR: no controllers found");
                exit(1);
        }

        //printf("Detected %d devices...\n", num_devs);
        int connection_count = 0;
        for (int i = 0; i < num_devs; i++) {

                libusb_device *dev = devs[i];

                if (libusb_get_device_descriptor(dev, &desc) < 0) {
                        printf("\nERROR: bad device descriptor.");
                        exit(1);
                }

                // Our controllers have idProduct of 17
                if (desc.idProduct == 17) {

                        //printf("FOUND: idProduct-%d ", desc.idProduct);
                        struct libusb_config_descriptor *config;
                        if ((libusb_get_config_descriptor(dev, 0, &config)) < 0) {
                                printf("\nERROR: bad config descriptor.");
                                exit(1);
                        }
                        //printf("interfaces-%d\n", config->bNumInterfaces);

                        // Our controllers only have a single interface, no need for looping
                        // This interface also only has one .num_altsetting, no need for looping

                        int r;
                        const struct libusb_interface_descriptor *inter = config->interface[0].altsetting;
                        if ((r = libusb_open(dev, &controller)) != 0) {
                                printf("\nERROR: couldn't open controller");
                                exit(1);
                        }
                        if (libusb_kernel_driver_active(controller, 0)) {
                                libusb_detach_kernel_driver(controller, 0);
                        }
                        libusb_set_auto_detach_kernel_driver(controller, 0);
                        if ((r = libusb_claim_interface(controller, 0)) != 0) {
                                printf("\nERROR: couldn't claim controller.");
                                exit(1);
                        }

                        endpoint_address = inter->endpoint[0].bEndpointAddress;
                        connection_count++;

                        if (connection_count == 1) {
                                devices.device1 = controller;
                                devices.device1_addr = endpoint_address;
                        } else {
                                devices.device2 = controller;
                                devices.device2_addr = endpoint_address;
                                //printf("%d:%d,%d:%d\n",devices.device1,devices.device1_addr,devices.device2,devices.device2_addr)                                goto found;
                        }
                }
        }

        if (connection_count < 2) {
                printf("ERROR: couldn't find 2 controllers.");
                exit(1);
        }

        found:
                printf("Connected %d controllers!\n", connection_count);
                libusb_free_device_list(devs, 1);

        return devices;
}

void detect_presses(struct controller_pkt pkt, char *buttons, int mode) {

        // Choose whether you want human-readable or binary output
        char vals[] = "LRUDA";
        if (mode == 1) {
                strcpy(buttons, "00000");
                strcpy(vals, "11111");
        } else {
                strcpy(buttons, "_____");
        }

        // Check left/right arrows (can only be one at a time)
        if (pkt.h_arrows == 0) {
                buttons[0] = vals[0];
        } else if (pkt.h_arrows == 255) {
                buttons[1] = vals[1];
        }

        // Check up/down arrows (can only be one at a time)
        if (pkt.v_arrows == 0) {
                buttons[2] = vals[2];
        } else if (pkt.v_arrows == 255) {
                buttons[3] = vals[3];
        }

        // Check if shoot button (A) is pressed
        uint8_t a = pkt.xyab;
        if (a == 47 || a == 63 || a == 111 || a == 127 || a == 175 || a == 191 || a == 239 || a == 255) {
                buttons[4] = vals[4];
        }

        //printf("\n%s", buttons);

}

void *listen_controllers(void *arg) {

        struct args_list *args_p = arg;
        struct args_list args = *args_p;
        struct controller_list devices = args.devices;

        struct controller_pkt pkt1, pkt2;
        int fields1, fields2;
        int size1 = sizeof(pkt1);
        int size2 = sizeof(pkt2);
        char buttons1[] = "_____";
        char buttons2[] = "_____";

        for (;;) {

                libusb_interrupt_transfer(devices.device1, devices.device1_addr, (unsigned char *) &pkt1, size1, &fields1, 0);
                libusb_interrupt_transfer(devices.device2, devices.device2_addr, (unsigned char *) &pkt2, size2, &fields2, 0);

                // 7 fields should be transferred for each packet
                if (fields1 == 7 && fields2 == 7) {
                        detect_presses(pkt1, buttons1, args.mode);
                        detect_presses(pkt2, buttons2, args.mode);
                        strcat(buttons1, buttons2);
                        strcpy(args.buttons, buttons1);
                        if (args.print == 1) {
                                printf("%s\n", args.buttons);
                        }
                }
        }
}






