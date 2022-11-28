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

//char CRC8(const char *data,int length);
uint8_t checksumCalculator(uint8_t *data, uint8_t length);
void getMsg0(int temp, int humidity, int raw_data);
void getMsg1(int temp, int humidity, int co2);
#endif
