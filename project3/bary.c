/* gcc bary.c -lgraph -lX11 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <X11/Xlib.h>
#include <graphics.h>

typedef struct {
	int x, y, z;
} Point;

Point initPoint(int x, int y, int z);
bool inTriangle(Point p, Point p1, Point p2, Point p3);
void Barycentric(Point p, Point a, Point b, Point c, float *u, float *v, float *w);
void computeEdges(Point p, Point a, Point b, Point c, int *, int *, int *);
Point diff(Point a, Point b);
float dot(Point a, Point b);

int main(void) {
	//XInitThreads();
	int gd, gm;
	detectgraph(&gd, &gm);
	initgraph(&gd, &gm,"e:\\tc\\bgi");

	Point p1 = initPoint(1, 1, 0);
	Point p2 = initPoint(20, 1, 0);
	Point p3 = initPoint(18, 22, 0);

	/* Bounded Box */
	int x, y, count = 0;
	for (y = 1; y <= 22; y++) {
		for (x = 1; x <= 20; x++) {
			Point p = initPoint(x, y, 0);
			if (inTriangle(p, p1, p2, p3)) {
				putpixel(x, y, WHITE);
			}
			count++;
		}
	}
	fprintf(stderr, "Using bounded box method: %d\n", count);

	/* Optimized */
	x = 18, y = 22, count = 0;
	bool in_triangle = true;
	bool add = true;
	while (y >= 1) {
		count++;
		Point p = initPoint(x, y, 0);
		while (inTriangle(p, p1, p2, p3)) {
			//putpixel(x, y, WHITE);
		    count ++;
		    if (add)
		        x++;
		    else 
		        x--;
		    p = initPoint(x, y, 0);
		}
		if (add)
		    x--;
		else
		    x++;
		y--;
		add = !add;
	}
	fprintf(stderr, "Using optimized zig-zag method: %d\n", count);

	delay(50000);
	return 0;
}

Point initPoint(int x, int y, int z) {
	Point p;
	p.x = x;
	p.y = y;
	p.z = z;
	return p;
} 

bool inTriangle(Point p, Point p1, Point p2, Point p3) {
    int e1, e2, e3;
	computeEdges(p, p1, p2, p3, &e1, &e2, &e3);
    if (e1 > 0 && e2 > 0 && e3 > 0)
        return true;
    return false;
}

void computeEdges(Point p, Point a, Point b, Point c, int *e1, int *e2, int *e3) {
	*e1 = -(c.y - b.y) * (p.x - b.x) + (c.x - b.x) * (p.y - b.y);
	*e2 = -(a.y - c.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y);
	*e3 = -(b.y - a.y) * (p.x - a.x) + (b.x - a.x) * (p.y - a.y);
}	

// Compute barycentric coordinates (u, v, w) for
// point p with respect to triangle (a, b, c)
void Barycentric(Point p, Point a, Point b, Point c, float *u, float *v, float *w)
{
	Point v0 = diff(b, a);
	Point v1 = diff(c, a);
	Point v2 = diff(p, a);
    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);
    float denom = d00 * d11 - d01 * d01;
    *v = (d11 * d20 - d01 * d21) / denom;
    *w = (d00 * d21 - d01 * d20) / denom;
    *u = 1.0f - *v - *w;
}

Point diff(Point a, Point b) {
	Point p;
	p.x = a.x - b.x;
	p.y = a.y - b.y;
	p.z = a.z - b.z;
	return p;
}

float dot(Point a, Point b) {
	return a.x * b.x + a.y * b.y + a.z * b.z;
}

