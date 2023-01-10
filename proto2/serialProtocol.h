/**************************************************************************/
/*!
@file     serialProtocol.h
@author   Antonio Solida
@license  GNU GPLv3

First version of serial data parser header for air-quality-monitor prototype
Header file used by serialProtocol.cpp

@section  HISTORY

v0.0.1 - First release
*/
/**************************************************************************/
#ifndef SERIALPROTOCOL_H_
#define SERIALPROTOCOL_H_ 

#include <stdint.h>

uint8_t checksumCalculator(uint8_t *data, uint8_t length);
void getMsg0(int temp, int humidity, int raw_data);
void getMsg1(int temp, int humidity, int co2);
void getMsg2(/*For future use*/);
void getMsg3();
void getMsg4(int temp, int humidity, int co2, uint8_t feedback);

void positive();
void neutral();
void negative();
#endif
