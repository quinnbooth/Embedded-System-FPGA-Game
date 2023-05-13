#ifndef _VGA_BALL_H
#define _VGA_BALL_H

#include <linux/ioctl.h>

typedef struct {
	unsigned short wall, misc, p1_tankl, p1_tankd, p2_tankl, p2_tankd,
  p1_bulletl, p1_bulletd, p2_bulletl, p2_bulletd;
  
} vga_ball_color_t;


typedef struct {
  vga_ball_color_t background;
} vga_ball_arg_t;


#define VGA_BALL_MAGIC 'q'

/* ioctls and their arguments */
#define VGA_BALL_WRITE_BACKGROUND _IOW(VGA_BALL_MAGIC, 1, vga_ball_arg_t *)
#define VGA_BALL_READ_BACKGROUND  _IOR(VGA_BALL_MAGIC, 2, vga_ball_arg_t *)

#endif
