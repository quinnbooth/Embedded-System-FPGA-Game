/*
 * Tanks Game userspace program that runs the game logic and 
 * communicates with the vga_ball device driver through ioctls
 *
 * Contributors:
 *
 * Quinn Booth
 * Columbia University
 *
 * Ganesan Narayanan
 * Columbia University
 *
 * Ana Maria Rodriguez
 * Columbia University
 *
 * Stephen A. Edwards
 * Columbia University
 *
 */

#include <stdio.h>
#include "vga_ball.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include "controller.h"
#include <libusb-1.0/libusb.h>
#include <stdlib.h>
#include <pthread.h>

struct controller_list open_controllers();

int vga_ball_fd;

unsigned short coords;
unsigned short coords2;

vga_ball_color_t color;

pthread_t p1b, p2b;

int map[300] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
int map2[300] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,1,1,0,1,1,1,0,1,1,1,0,0,1,1,1,0,1,1,1,0,1,1,0,1,1,0,0,0,1,0,0,0,0,1,0,0,0,1,1,0,1,1,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,1,1,0,1,0,0,1,0,0,0,1,1,0,0,0,1,0,0,1,0,1,1,0,0,0,1,1,1,0,1,1,1,1,0,1,1,1,0,0,0,1,1,0,0,0,1,1,1,0,1,1,1,1,0,1,1,1,0,0,0,1,1,0,1,0,0,1,0,0,0,1,1,0,0,0,1,0,0,1,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,1,1,0,0,0,1,0,0,0,0,1,0,0,0,1,1,0,1,1,0,1,1,1,0,1,1,1,0,0,1,1,1,0,1,1,1,0,1,1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
int map3[300] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1,0,1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1,0,1,1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1,1,0,1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1,0,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,1,1,1,1,0,0,1,1,0,0,1,1,1,1,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};


struct bullet_args {
  unsigned short cur_coords;
  int dir;
};

struct bullet_args args1;
struct bullet_args args2;

int p1_hit = 0;
int p2_hit = 0;

int p1_has_fired = 0;
int p2_has_fired = 0;

int map_num = 0;

/* Read and print the background color
void print_background_color() {
  vga_ball_arg_t vla;
  
  if (ioctl(vga_ball_fd, VGA_BALL_READ_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_READ_BACKGROUND) failed");
      return;
  }
  printf("%02x %02x %02x\n",
	 vla.background.red, vla.background.green, vla.background.blue);
}
*/

/* Set the background color */
void set_background_color(const vga_ball_color_t *c)
{
  vga_ball_arg_t vla;
  vla.background = *c;
  if (ioctl(vga_ball_fd, VGA_BALL_WRITE_BACKGROUND, &vla)) {
      perror("ioctl(VGA_BALL_SET_BACKGROUND) failed");
      return;
  }
}

int check_collision_wall(unsigned short coords)
{
  // returns 1 if collision
  
  // convert to tile

  unsigned char h_coords = coords >> 8;
  unsigned char v_coords = coords;

  unsigned int tile32_x = h_coords >> 3;
  unsigned int tile32_y = v_coords >> 3;

  if (map_num == 0) {
    if (map[tile32_x + tile32_y * 20] == 1)
      return 1;
  }
  else if(map_num == 1) {
    if (map2[tile32_x + tile32_y * 20] == 1)
      return 1;
  }
  else if(map_num == 2) {
    if (map3[tile32_x + tile32_y * 20] == 1)
      return 1;
  }

  return 0;
}

int check_collision_tank(unsigned short coords, unsigned short coords2)
{
  // returns 1 if collision
  
  // convert to tile

  unsigned char h_coords = coords >> 8;
  unsigned char v_coords = coords;

  unsigned int tile32_x = h_coords >> 3;
  unsigned int tile32_y = v_coords >> 3;

  unsigned char h_coords2 = coords2 >> 8;
  unsigned char v_coords2 = coords2;

  unsigned int tile32_x2 = h_coords2 >> 3;
  unsigned int tile32_y2 = v_coords2 >> 3;

  if (tile32_x == tile32_x2 && tile32_y == tile32_y2)
    return 1;

  return 0;
}

void *fire_bullet_p1(void *args) {

  p2_hit = 0;

  struct bullet_args *bullet_info = (struct bullet_args *) args;
  unsigned short cur_coords = bullet_info->cur_coords;
  int dir = bullet_info->dir;

  // convert to tile

  short init_inc = 0b010;
  short inc = 0b0010;
  int result;
  short offset = 0b100;

  if (dir == 0b00) {

    cur_coords -= init_inc;
    cur_coords += offset * 256;
  }
  else if (dir == 0b01) {

    cur_coords += init_inc;
    cur_coords += offset * 256;
  }
  else if (dir == 0b10) {

    cur_coords -= init_inc * 256;
    cur_coords += offset;
  }
  else {

    cur_coords += init_inc * 256;
    cur_coords += offset;
  }

  for (;;) {

    if (dir == 0b00) {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords2) == 1) {
        
        result = 1;
        break;
      }
      
      else {

        color.p1_bulletl = cur_coords;
        color.p1_bulletd = 0b1000000000000000;        
        set_background_color(&color);
	usleep(17000);

	cur_coords -= inc;

      }

    }
    else if (dir == 0b01) {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords2) == 1) {

        result = 1;
        break;
      }
      
      else {

        color.p1_bulletl = cur_coords;
        color.p1_bulletd = 0b1000000000000000;
        set_background_color(&color);
	usleep(17000);

	cur_coords += inc;
      }

    }
    else if (dir == 0b10) {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords2) == 1) {

        result = 1;
        break;
      }
      
      else {

        color.p1_bulletl = cur_coords;
        color.p1_bulletd = 0b1000000000000000;
        set_background_color(&color);
	usleep(17000);

	cur_coords -= inc * 256;
      }

    }
    else {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords2) == 1) {

        result = 1;
        break;
      }
      
      else {

        color.p1_bulletl = cur_coords;
        color.p1_bulletd = 0b1000000000000000;
        set_background_color(&color);
	usleep(17000);

	cur_coords += inc * 256;
      }

    }
  }

  //color.p1_bulletl = 0b0000000000000000;
  color.p1_bulletd = 0b0000000000000000;
  set_background_color(&color);

  p2_hit = result;
  p1_has_fired = 0;
}

void *fire_bullet_p2(void *args) {

  p1_hit = 0;

  struct bullet_args *bullet_info = (struct bullet_args *) args;
  unsigned short cur_coords = bullet_info->cur_coords;
  int dir = bullet_info->dir;

  // convert to tile

  short init_inc = 0b010;
  short inc = 0b0010;
  int result;
  short offset = 0b100;

  if (dir == 0b00) {

    cur_coords -= init_inc;
    cur_coords += offset * 256;
  }
  else if (dir == 0b01) {

    cur_coords += init_inc;
    cur_coords += offset * 256;
  }
  else if (dir == 0b10) {

    cur_coords -= init_inc * 256;
    cur_coords += offset;
  }
  else {

    cur_coords += init_inc * 256;
    cur_coords += offset;
  }

  for (;;) {

    if (dir == 0b00) {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords) == 1) {
        
        result = 1;
        break;
      }
      
      else {

        color.p2_bulletl = cur_coords;
        color.p2_bulletd = 0b1000000000000000;        
        set_background_color(&color);
	usleep(17000);

	cur_coords -= inc;
      }

    }
    else if (dir == 0b01) {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords) == 1) {

        result = 1;
        break;
      }
      
      else {

        color.p2_bulletl = cur_coords;
        color.p2_bulletd = 0b1000000000000000;
        set_background_color(&color);
	usleep(17000);

	cur_coords += inc;
      }

    }
    else if (dir == 0b10) {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords) == 1) {

        result = 1;
        break;
      }
      
      else {

        color.p2_bulletl = cur_coords;
        color.p2_bulletd = 0b1000000000000000;
        set_background_color(&color);
	usleep(17000);

	cur_coords -= inc * 256;
      }

    }
    else {

      if (check_collision_wall(cur_coords) == 1) {

        result = 0;
        break;
      }

      else if (check_collision_tank(cur_coords, coords) == 1) {

        result = 1;
        break;
      }
      
      else {

        color.p2_bulletl = cur_coords;
        color.p2_bulletd = 0b1000000000000000;
        set_background_color(&color);
	usleep(17000);

	cur_coords += inc * 256;
      }

    }
  }

  //color.p2_bulletl = 0b0000000000000000;
  color.p2_bulletd = 0b0000000000000000;
  set_background_color(&color);

  p2_has_fired = 0;
  p1_hit = result;
}

int main()
{
  vga_ball_arg_t vla;
  static const char filename[] = "/dev/vga_ball";

  static const vga_ball_color_t colors[] = {
    { 0xff, 0x00, 0x00 }, /* Red */
    { 0x00, 0xff, 0x00 }, /* Green */
    { 0x00, 0x00, 0xff }, /* Blue */
    { 0xff, 0xff, 0x00 }, /* Yellow */
    { 0x00, 0xff, 0xff }, /* Cyan */
    { 0xff, 0x00, 0xff }, /* Magenta */
    { 0x80, 0x80, 0x80 }, /* Gray */
    { 0x00, 0x00, 0x00 }, /* Black */
    { 0xff, 0xff, 0xff }  /* White */
  };


# define COLORS 9

  printf("Tanks Game Userspace program started\n");

  if ( (vga_ball_fd = open(filename, O_RDWR)) == -1) {
    fprintf(stderr, "could not open %s\n", filename);
    return -1;
  }


struct controller_list devices = open_controllers();

struct controller_pkt pkt1, pkt2;
int fields1, fields2;
int size1 = sizeof(pkt1);
int size2 = sizeof(pkt2);

for (;;) {

map_num = 0;

unsigned char h_coords;
unsigned char v_coords;

short inc = 0b1000;

int p1_left = 0;
int p1_right = 0;
int p1_up = 0;
int p1_down = 0;
int p1_fire = 0;
int p2_left = 0;
int p2_right = 0;
int p2_up = 0;
int p2_down = 0;
int p2_fire = 0;

int p1_score = 0;
int p2_score = 0;

int time = 80000;

int starting_press = 12;

coords = 0b0010000000100000;
unsigned short data = 0b1100000000000000;
coords2 = 0b0111100000100000;
unsigned short data2 = 0b1000000000000000;
unsigned short wall = 0b0000000000000000;
unsigned short misc = 0b0000000000000000;

color.wall = wall;
color.misc = misc;
color.p1_tankl = coords;
color.p1_tankd = data;
color.p2_tankl = coords2;
color.p2_tankd = data2;
color.p1_bulletl = 0;
color.p1_bulletd = 0;
color.p2_bulletl = 0;
color.p2_bulletd = 0;

set_background_color(&color);

// pre-game loop

for (;;) {

  //map_num = 0;

  libusb_interrupt_transfer(devices.device1, devices.device1_addr, (unsigned char *) &pkt1, size1, &fields1, 0);
  libusb_interrupt_transfer(devices.device2, devices.device2_addr, (unsigned char *) &pkt2, size2, &fields2, 0);

  if (fields1 == 7 && fields2 == 7) {
    
    uint8_t a = pkt1.xyab;
    
    if (pkt1.v_arrows == 0) {

      p1_up += 1;
      if (p1_up >= 12) {
        p1_up = 0;

      if (wall == 0b0000000000000000) {
        
        map_num = 1;
        wall = 0b0100000000000000;
        time = 50000;
      }
      else if (wall == 0b0100000000000000) {

        map_num = 2;
        wall = 0b1000000000000000;
        time = 30000;
      }
      
      color.wall = wall;
      set_background_color(&color);

      coords = 0b0010000000100000;
      data = 0b1100000000000000;
      coords2 = 0b0111100000100000;
      data2 = 0b1000000000000000;

      while (coords <= 0b0100100000100000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords += inc * 256;
          coords2 -= inc * 256;
      }

      data = 0b0100000000000000;
      data2 = 0b0100000000000000;

      while (coords <= 0b0100100001001000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords += inc;
          coords2 += inc;
      }

      data = 0b1000000000000000;
      data2 = 0b1100000000000000;

      while (coords >= 0b0010000001001000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords -= inc * 256;
          coords2 += inc * 256;
      }

      data = 0b0000000000000000;
      data2 = 0b0000000000000000;

      while (coords >= 0b0010000000100000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords -= inc;
          coords2 -= inc;
      }


      }

    } else if (pkt1.v_arrows == 255) {

      p1_down += 1;
      if (p1_down >= 12) {
        p1_down = 0;

      if (wall == 0b1000000000000000) {
        
        map_num = 1;
        wall = 0b0100000000000000;
        time = 50000;
      }
      else if (wall == 0b0100000000000000) {

        map_num = 0;
        wall = 0b0000000000000000;
        time = 80000;
      }
      
      color.wall = wall;
      set_background_color(&color);

      coords = 0b0010000000100000;
      data = 0b1100000000000000;
      coords2 = 0b0111100000100000;
      data2 = 0b1000000000000000;

      while (coords <= 0b0100100000100000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords += inc * 256;
          coords2 -= inc * 256;
      }

      data = 0b0100000000000000;
      data2 = 0b0100000000000000;

      while (coords <= 0b0100100001001000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords += inc;
          coords2 += inc;
      }

      data = 0b1000000000000000;
      data2 = 0b1100000000000000;

      while (coords >= 0b0010000001001000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords -= inc * 256;
          coords2 += inc * 256;
      }

      data = 0b0000000000000000;
      data2 = 0b0000000000000000;

      while (coords >= 0b0010000000100000) {

          color.p1_tankl = coords;
          color.p1_tankd = data;
          color.p2_tankl = coords2;
          color.p2_tankd = data2;
          set_background_color(&color);
          usleep(time);

          coords -= inc;
          coords2 -= inc;
      }

      }

    } else if (a == 47 || a == 63 || a == 111 || a == 127 || a == 175 || a == 191 || a == 239 || a == 255) {

      p1_fire += 1;
      if (p1_fire >= 15) {
        p1_fire = 0;


	printf("Selected Map #%d...\n", map_num + 1);

      if (map_num == 0) {

        misc = 0b0000000000000000;
	wall = 0b0000000000000100;
      }
      else if (map_num == 1) {

        misc = 0b0000000000000001;
	wall = 0b0100000000000100;
      }
      else {

        misc = 0b0000000000000010;
	wall = 0b1000000000000100;
      }

      break;
    }

    }

  }

}


coords = 0b0000100001101000;
data = 0b0000000000000000;
coords2 = 0b1001000000010000;
data2 = 0b0100000000000000;

color.wall = wall;
color.misc = misc;
color.p1_tankl = coords;
color.p1_tankd = data;
color.p2_tankl = coords2;
color.p2_tankd = data2;

set_background_color(&color);


for (;;) {

    if (p1_hit == 1) {

      p2_score += 1;

      unsigned short h = coords >> 9;
      unsigned char v = coords;

      unsigned char v_trunc = coords >> 1;

      unsigned int h_int = h * 512;
      unsigned int v_int = v_trunc * 4;

      unsigned short ex_coords = h_int + v_int + misc;

      color.misc = ex_coords;
      wall |= 0b0000000000010000;
      color.wall = wall;
      set_background_color(&color);

      usleep(150000);

      wall |= 0b0000000001000000;
      color.wall = wall;
      set_background_color(&color);

      usleep(150000);

      wall |= 0b0000000010000000;
      wall &= 0b1111111110111111;
      color.wall = wall;
      set_background_color(&color);

      // join threads so that hit gets reset

      pthread_cancel(p1b);
      p1_hit = 0;
      p2_hit = 0;

      color.p1_bulletd = 0b0000000000000000;
      set_background_color(&color);
      p1_has_fired = 0;

      usleep(150000);

      if (p2_score == 5) {

        wall |= 0b0000010000100000;
        wall &= 0b1111110011111111;
        color.wall = wall;
        set_background_color(&color);

        p1_score = 0;
        p2_score = 0;

        usleep(2500000);

        // reset wall for next time

        printf("P2 wins!\n");

	break;

      }
      else if (p2_score == 4) {

        wall |= 0b0000001100000000;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      else if (p2_score == 3) {

        wall |= 0b0000001000000000;
        wall &= 0b1111111011111111;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      else if (p2_score == 2) {

        wall |= 0b0000000100000000;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      else if (p2_score == 1) {

        wall |= 0b0000000000000010;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      // reset back to starting positions

      wall &= 0b1111111100101111;
      coords = 0b0000100001101000;
      data = 0b0000000000000000;
      coords2 = 0b1001000000010000;
      data2 = 0b0100000000000000;
      color.wall = wall;
      color.p1_tankl = coords;
      color.p1_tankd = data;
      color.p2_tankl = coords2;
      color.p2_tankd = data2;
      set_background_color(&color); 

    }

    else if (p2_hit == 1) {

      p1_score += 1;

      unsigned short h = coords2 >> 9;
      unsigned char v = coords2;

      unsigned char v_trunc = coords2 >> 1;

      unsigned int h_int = h * 512;
      unsigned int v_int = v_trunc * 4;

      unsigned short ex_coords = h_int + v_int + misc;

      color.misc = ex_coords;

      wall |= 0b0000000000010000;
      color.wall = wall;
      set_background_color(&color);

      usleep(150000);

      wall |= 0b0000000001000000;
      color.wall = wall;
      set_background_color(&color);

      usleep(150000);

      wall |= 0b0000000010000000;
      wall &= 0b1111111110111111;
      color.wall = wall;
      set_background_color(&color);

      pthread_cancel(p2b);
      p1_hit = 0;
      p2_hit = 0;

      color.p2_bulletd = 0b0000000000000000;
      set_background_color(&color);
      p2_has_fired = 0;

      usleep(150000);

      if (p1_score == 5) {

        wall |= 0b0010000000100000;
        wall &= 0b1110011111111111;
        color.wall = wall;
        set_background_color(&color);

        p1_score = 0;
        p2_score = 0;

        usleep(2500000);

        // reset wall for next time

	printf("P1 wins!\n");

        break;

      }
      else if (p1_score == 4) {

        wall |= 0b0001100000000000;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      else if (p1_score == 3) {

        wall |= 0b0001000000000000;
        wall &= 0b1111011111111111;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      else if (p1_score == 2) {

        wall |= 0b0000100000000000;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      else if (p1_score == 1) {

        wall |= 0b0000000000001000;
        color.wall = wall;
        set_background_color(&color);

        usleep(300000);
      }

      // reset back to starting positions

      wall &= 0b1111111100101111;
      coords = 0b0000100001101000;
      data = 0b0000000000000000;
      coords2 = 0b1001000000010000;
      data2 = 0b0100000000000000;
      color.wall = wall;
      color.p1_tankl = coords;
      color.p1_tankd = data;
      color.p2_tankl = coords2;
      color.p2_tankd = data2;
      set_background_color(&color);

    }

    libusb_interrupt_transfer(devices.device1, devices.device1_addr, (unsigned char *) &pkt1, size1, &fields1, 0);
    libusb_interrupt_transfer(devices.device2, devices.device2_addr, (unsigned char *) &pkt2, size2, &fields2, 0);

    if (fields1 == 7 && fields2 == 7) {

        // do detecting pkts for each

        uint8_t a = pkt1.xyab;

        // Check left/right arrows (can only be one at a time)
        if (pkt1.h_arrows == 0) {

            p1_left += 1;
            if (p1_left >= 12) {
              p1_left = 0;

            // left

	    h_coords = coords >> 8;

            if (h_coords > 0b00000000) {

                coords -= inc * 256;

                if (check_collision_wall(coords) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data = 0b1000000000000000;

                  color.p1_tankl = coords;
                  color.p1_tankd = data;
                  set_background_color(&color);
                }
                else {

                  coords += inc * 256;
                }
            }
            }

        } else if (pkt1.h_arrows == 255) {

            p1_right += 1;
            if (p1_right >= 12) {
              p1_right = 0;

            // right

	    h_coords = coords >> 8;

            if (h_coords < 0b10011000) {

                coords += inc * 256;

                if (check_collision_wall(coords) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data = 0b1100000000000000;

                  color.p1_tankl = coords;
                  color.p1_tankd = data;
                  set_background_color(&color);
                }
                else {
                  
                  coords -= inc * 256;
                }

            }
            }

        }

        // Check up/down arrows (can only be one at a time)
        else if (pkt1.v_arrows == 0) {

            p1_up += 1;
            if (p1_up >= 12) {
              p1_up = 0;

            // up

            v_coords = coords;

            if (v_coords > 0b00000000) {

                coords -= inc;

                if (check_collision_wall(coords) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data = 0b0000000000000000;

                  color.p1_tankl = coords;
                  color.p1_tankd = data;
                  set_background_color(&color);
                }
                else {

                  coords += inc;
                }
            }
            }

        } else if (pkt1.v_arrows == 255) {

            p1_down += 1;
            if (p1_down >= 12) {
              p1_down = 0;
            
            // down

            v_coords = coords;

            if (v_coords < 0b01110000) {

                coords += inc;
                
                if (check_collision_wall(coords) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data = 0b0100000000000000;

                  color.p1_tankl = coords;
                  color.p1_tankd = data;
                  set_background_color(&color);
                }
                else {

                  coords -= inc;
                }
            }
            }

        }

        // Check if shoot button (A) is pressed
        else if (a == 47 || a == 63 || a == 111 || a == 127 || a == 175 || a == 191 || a == 239 || a == 255) {


	    p1_fire += 1;
            if (p1_fire >= 15) {
              p1_fire = 0;

		  if (p1_has_fired == 0) {

		    p1_has_fired = 1;

		    args1.cur_coords = coords;
            	    args1.dir = data >> 14;

            	    pthread_create(&p1b, NULL, &fire_bullet_p1, (void *) &args1);

		  }
          }

        }




        uint8_t b = pkt2.xyab;

        // Check left/right arrows (can only be one at a time)
        if (pkt2.h_arrows == 0) {

            p2_left += 1;
            if (p2_left >= 12) {
              p2_left = 0;

            // left

            h_coords = coords2 >> 8;

            if (h_coords > 0b00000000) {

                coords2 -= inc * 256;

                if (check_collision_wall(coords2) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data2 = 0b1000000000000000;

                  color.p2_tankl = coords2;
                  color.p2_tankd = data2;
                  set_background_color(&color);
                }
                else {

                  coords2 += inc * 256;
                }
            }
            }

        } else if (pkt2.h_arrows == 255) {

            p2_right += 1;
            if (p2_right >= 12) {
              p2_right = 0;

            // right

            h_coords = coords2 >> 8;

            if (h_coords < 0b10011000) {

                coords2 += inc * 256;

                if (check_collision_wall(coords2) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data2 = 0b1100000000000000;

                  color.p2_tankl = coords2;
                  color.p2_tankd = data2;
                  set_background_color(&color);
                }
                else {

                  coords2 -= inc * 256;
                }
            }
            }

        }

        // Check up/down arrows (can only be one at a time)
        else if (pkt2.v_arrows == 0) {

            p2_up += 1;
            if (p2_up >= 12) {
              p2_up = 0;

            // up

	    v_coords = coords2;
            
            if (v_coords > 0b00000000) {

                coords2 -= inc;

                if (check_collision_wall(coords2) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data2 = 0b0000000000000000;

                  color.p2_tankl = coords2;
                  color.p2_tankd = data2;
                  set_background_color(&color);
                }
                else {

                  coords2 += inc;
                }
            }
            }

        } else if (pkt2.v_arrows == 255) {

            p2_down += 1;
            if (p2_down >= 12) {
              p2_down = 0;

            // down

            v_coords = coords2;

            if (v_coords < 0b01110000) {

                coords2 += inc;

                if (check_collision_wall(coords2) == 0 && check_collision_tank(coords, coords2) == 0) {

                  data2 = 0b0100000000000000;

                  color.p2_tankl = coords2;
                  color.p2_tankd = data2;
                  set_background_color(&color);
                }
                else {

                  coords2 -= inc;
                }
            }
            }

        }

        // Check if shoot button (A) is pressed
        else if (b == 47 || b == 63 || b == 111 || b == 127 || b == 175 || b == 191 || b == 239 || b == 255) {


	    p2_fire += 1;
            if (p2_fire >= 15) {
              p2_fire = 0;


		  if (p2_has_fired == 0) {

		    p2_has_fired = 1;
		  
		    args2.cur_coords = coords2;
            	    args2.dir = data2 >> 14;

            	    pthread_create(&p2b, NULL, &fire_bullet_p2, (void *) &args2);

		  }
	    }

        }


    }
}
}
  
  printf("Tanks Game Userspace program terminating\n");
  return 0;


}
