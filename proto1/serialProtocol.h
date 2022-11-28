#ifndef SERIALPROTOCOL_H_
#define SERIALPROTOCOL_H_ 
#if ARDUINO >= 100
 #include "Arduino.h"
#else
 #include "WProgram.h"
#endif

char getCRC8(const char *data,int length);
char getMsg1(int temp, int humidity, int co2);
char getMsg3();
#endif
