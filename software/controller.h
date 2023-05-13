#ifndef _CONTROLLER_H
#define _CONTROLLER_H

#include <stdio.h>
#include <stdlib.h>
#include <libusb-1.0/libusb.h>

struct controller_list {

        struct libusb_device_handle *device1;
        struct libusb_device_handle *device2;
        uint8_t device1_addr;
        uint8_t device2_addr;

};

struct controller_pkt {

        uint8_t const1;
        uint8_t const2;
        uint8_t const3;
        uint8_t h_arrows;
        uint8_t v_arrows;
        uint8_t xyab;
        uint8_t rl;

};

struct args_list {

        struct controller_list devices;
        char * buttons;
        int mode;
        int print;

};

extern struct controller_list open_controller(uint8_t *);

#endif

