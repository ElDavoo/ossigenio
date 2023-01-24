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
extern volatile uint8_t feedback;

#define MODEL 1
#define VERSION 1

void getMsg0(int temp, int humidity, int raw_data){
    uint8_t buffer[8];

    buffer[0] = 0xAA;
    buffer[1] = 0x80;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(raw_data);
    buffer[5] = lowByte(raw_data);
    buffer[6] = 0xFF;

    uint8_t message[4];

    message[0] = (uint8_t) 0xAA80;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) raw_data;

    uint8_t crc = checksumCalculator(message,4);
    buffer[7] = crc;
    ble.write(buffer,8);
}

void getMsg1(int temp, int humidity, int co2) {
    uint8_t buffer[8];

    buffer[0] = 0xAA;
    buffer[1] = 0x81;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(co2);
    buffer[5] = lowByte(co2);
    buffer[6] = 0xFF;
    
    uint8_t message[4];

    message[0] = (uint8_t) 0xAA81;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) co2;

    uint8_t crc = checksumCalculator(message,4);
    buffer[7] = crc;
    ble.write(buffer,8);
}

void getMsg2(/*NOT YET IMPLEMENTED*/){
    //TO DO
}

void getMsg3(){
    uint8_t battery = 100;
    uint8_t buffer[7];

    buffer[0] = 0xAA;
    buffer[1] = 0x83;
    buffer[2] = (uint8_t) MODEL;
    buffer[3] = (uint8_t) VERSION;
    buffer[4] = battery;
    buffer[5] = 0xFF;

    uint8_t message[4];

    message[0] = (uint8_t) 0xAA83;
    message[1] = (uint8_t) MODEL;
    message[2] = (uint8_t) VERSION;
    message[3] = (uint8_t) 0;

    uint8_t crc = checksumCalculator(message,4);
    buffer[6] = crc;
    ble.write(buffer,7); 
}

void getMsg4(int temp, int humidity, int co2, uint8_t feedback) {
    uint8_t buffer[9];

    buffer[0] = 0xAA;
    buffer[1] = 0x81;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(co2);
    buffer[5] = lowByte(co2);
    buffer[6] = feedback;
    buffer[7] = 0xFF;

    uint8_t message[5];

    message[0] = (uint8_t) 0xAA81;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) co2;
    message[4] = (uint8_t) feedback;

    uint8_t crc = checksumCalculator(message,5);
    buffer[8] = crc;
    ble.write(buffer,9);
}

uint8_t checksumCalculator(uint8_t *data, uint8_t length){
    uint8_t curr_crc = 0x0000;
    uint8_t sum1 = (uint8_t) curr_crc;
    uint8_t sum2 = (uint8_t) (curr_crc >> 8);
    int index;
    for(index = 0; index < length; index = index+1) {
    sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
    }
    return (sum2 << 8) | sum1;
}

void positive(){
    feedback=1;
}
void neutral(){
    feedback=2;
}
void negative(){
    feedback=3;
}