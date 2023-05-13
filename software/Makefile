ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := vga_ball.o

else

# We are being compiled as a module: use the Kernel build system

	KERNEL_SOURCE := /usr/src/linux-headers-$(shell uname -r)
        PWD := $(shell pwd)

default: module hello

hello: hello.o controller.o
	cc -Wall -o hello hello.o controller.o -lusb-1.0 -pthread -lm

hello.o: hello.c controller.h
controller.o: controller.c controller.h

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} hello

TARFILES = Makefile README vga_ball.h vga_ball.c hello.c controller.h controller.c
TARFILE = lab3-sw.tar.gz
.PHONY : tar
tar : $(TARFILE)

$(TARFILE) : $(TARFILES)
	tar zcfC $(TARFILE) .. $(TARFILES:%=lab3-sw/%)

endif 
