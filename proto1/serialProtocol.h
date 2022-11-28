/**************************************************************************/
/*!
@file     serialProtocol.h
@author   Antonio Solida
@license  GNU GPLv3

First version of serial data parser header for air-quality-monitor prototype

@section  HISTORY

v0.0.1 - First release
*/
/**************************************************************************/
#ifndef SERIALPROTOCOL_H_
#define SERIALPROTOCOL_H_ 
#if ARDUINO >= 100
 #include "Arduino.h"
#else
 #include "WProgram.h"
#endif

char getCRC8(const char *data,int length);
char getMsg0(int temp, int humidity, int raw_data);
char getMsg1(int temp, int humidity, int co2);
char getMsg3();
#endif
