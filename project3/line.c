/*
*  line.c 
*

*/

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <graphics.h>
#include <X11/Xlib.h>

int absolute_value(int n) {
  if (n < 0) {
    return (-1 * n);
  }
  return n;
}

int main(void)
{
  XInitThreads();
  int gd,gm;
  int x1, x2, y1, y2; 
  float dy, dx, m; 
  
  x1 = 0; y1 = 0; x2 = 10; y2 = 10; 

  fprintf(stderr, "draw a line between (%d, %d) to (%d, %d)\n", x1,y1, x2,y2); 

  /* Basic Incremental Algorithm */ 
  dy = y2 - y1; 
  dx = x2 - x1; 
  m = dy / dx;
  int adjust = (m >= 0) ? 1 : -1;
  long offset = 0; 
  detectgraph(&gd,&gm);
  initgraph(&gd,&gm,"e:\\tc\\bgi");
  if (m <= 1 && m >= -1) {
    fprintf(stderr, "m is between -1 and 1\n");
    long delta = absolute_value(dy) * 2;
    long threshold = absolute_value(dx);
    long threshold_inc = absolute_value(dx) * 2;
    int x1_new = x1;
    int x2_new = x2;
    int y = y1;
    if (x2 < x1) {
      x1_new = x2;
      x2_new = x1;
      y = y2;
    }
    for (int x = x1_new; x < x2_new + 1; x++) {
      putpixel(x, y, WHITE);
      fprintf(stderr, "(%d, %d)\n", x, y);
      offset += delta;
      if (offset >= threshold) {
        y += adjust;
        threshold += threshold_inc;
      }
    }
  }
  else {
    fprintf(stderr, "m is less than -1 or greater than 1\n");
    long delta = absolute_value(dx) * 2;
    long threshold = absolute_value(dy);
    long threshold_inc = absolute_value(dy) * 2;
    int y1_new = y1;
    int y2_new = y2;
    int x = x1;
    if (y2 < y1) {
      y1_new = y2;
      y2_new = y1;
      x = x2;
    }
    for (int y = y1_new; y < y2_new + 1; y++) {
      putpixel(x, y, WHITE);
      fprintf(stderr, "(%d, %d)\n", x, y);
      offset += delta;
      if (offset >= threshold) {
        x += adjust;
        threshold += threshold_inc;
      }
    }
  }

  delay(50000);
  closegraph();
  return 0;
}

