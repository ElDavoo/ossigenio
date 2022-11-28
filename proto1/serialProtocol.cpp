/**************************************************************************/
/*!
@file     serialProtocol.cpp
@author   Antonio Solida
@license  GNU GPLv3

First version of serial data parser for air-quality-monitor prototype

@section  HISTORY

v0.0.1 - First release
v0.0.2 - crc8 e getMsg1 initial implementation
v0.0.3 - getMsg3 initial implementation
v0.0.4 - getMsg0 initial implementation - ONLY FOR DEBUG USE
v0.0.5 - rewrited getMsg1 and getMsg3
*/
/**************************************************************************/
#include "serialProtocol.h"
#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_SPI.h"
#include "Adafruit_BluefruitLE_UART.h"
#include "BluefruitConfig.h"
extern Adafruit_BluefruitLE_SPI ble;

#define MODEL 0.1
#define VERSION 0.1

void getMsg0(int temp, int humidity, int raw_data){
    //TO BE IMPLEMENTED
}

void getMsg1(int temp, int humidity, int co2) {
    ble.print(0xa1); //questo valore qui è stampato come 161 nel monitor seriale
	ble.print(temp); 
	ble.print(humidity); 
    ble.print(co2);

    uint8_t message[4];

    message[0] = (uint8_t) 0xA1;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) co2;

    int crc = checksumCalculator(message,4);
    ble.print(0xff); //PLACEHOLDER per separare il valore di co2 dal crc
    ble.print(crc);
}

void getMsg3(){
    ble.print(0xa3); //questo valore qui è stampato come ___ nel monitor seriale
	ble.print(MODEL); 
	ble.print(VERSION); 

    uint8_t message[4];

    message[0] = (uint8_t) 0xa3;
    message[1] = (uint8_t) MODEL;
    message[2] = (uint8_t) VERSION;

    int crc = checksumCalculator(message,4);
    ble.print(0xff); //PLACEHOLDER per separare il valore di co2 dal crc
    ble.print(crc);
}

uint8_t checksumCalculator(uint8_t *data, uint8_t length){
   uint8_t curr_crc = 0x0000;
   uint8_t sum1 = (uint8_t) curr_crc;
   uint8_t sum2 = (uint8_t) (curr_crc >> 8);
   int index;
   for(index = 0; index < length; index = index+1)
   {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
   }
   return (sum2 << 8) | sum1;
}