#ifndef UTIL_H
#define UTIL_H

#include "stdint.h"


uint32_t MAXINT=4294967295;
double INF = 10000000;

uint32_t min (uint32_t x, uint32_t y) {
    return x<y ? x : y;  // returns minimum of x and y/
}


uint32_t max (uint32_t x, uint32_t y) {
    return x>y ? x : y;  // returns minimum of x and y/
}

uint32_t abs32(uint32_t x){
  return x>0 ? x : -x;  
}

#endif
