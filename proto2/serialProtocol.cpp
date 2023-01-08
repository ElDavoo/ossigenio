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
#include "BleSerial.h"
extern BleSerial ble;
extern volatile uint8_t feedback;
extern volatile bool feed;
#include <stdint.h>
#include "serialNumber.h"
extern const uint32_t serialNumber;

#define lowByte(w) ((uint8_t) ((w) & 0xff)) // esp32 seems not have lowByte and highByte functions ootb
#define highByte(w) ((uint8_t) ((w) >> 8)) // declared in this way to save memory

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
    uint8_t message[4];

    message[0] = (uint8_t) 0xAA81;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) co2;

    buffer[0] = 0xAA;
    buffer[1] = 0x81;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(co2);
    buffer[5] = lowByte(co2);
    buffer[6] = 0xFF;
    uint8_t crc = checksumCalculator(message,4);
    buffer[7] = crc;
    ble.write(buffer,8);
}

void getMsg2(/*NOT YET IMPLEMENTED*/){
    //RESERVED FOR FUTURE USE
}

void getMsg3(){
    uint8_t battery = 100;
    uint8_t buffer[11];
    buffer[0] = 0xAA;
    buffer[1] = 0x83;
    buffer[2] = (uint8_t) MODEL;
    buffer[3] = (uint8_t) VERSION;
    buffer[4] = (uint8_t) ((serialNumber) >> 24); //primo byte
    buffer[5] = (uint8_t) (((serialNumber) & 0x00ff0000) >> 16); //secondo
    buffer[6] = (uint8_t) (((serialNumber) & 0x0000ff00) >> 8); //terzo
    buffer[7] = (uint8_t) (((serialNumber) & 0x000000ff)); //quarto
    buffer[8] = battery;
    buffer[9] = 0xFF;

    uint8_t message[9];

    message[0] = (uint8_t) 0xAA;
    message[1] = (uint8_t) 0x83;
    message[2] = (uint8_t) MODEL;
    message[3] = (uint8_t) VERSION;
    message[4] = (uint8_t) ((serialNumber) >> 24); //primo byte
    message[5] = (uint8_t) (((serialNumber) & 0x00ff0000) >> 16); //secondo
    message[6] = (uint8_t) (((serialNumber) & 0x0000ff00) >> 8); //terzo
    message[7] = (uint8_t) (((serialNumber) & 0x000000ff)); //quarto
    message[8] = (uint8_t) battery;

    uint8_t crc = checksumCalculator(message,9); 
    buffer[10] = crc;
    ble.write(buffer,11); 
}

void getMsg4(int temp, int humidity, int co2, uint8_t feedback) {
    uint8_t buffer[9];

    buffer[0] = 0xAA;
    buffer[1] = 0x84;
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
   for(index = 0; index < length; index = index+1)
   {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
   }
   return (sum2 << 8) | sum1;
}

void positive(){
    //ble.print("Think positive!"); //DEBUG
    feedback=1;
    feed = true;
}
void neutral(){
    //ble.print("N"); //DEBUG
    feedback=2;
    feed = true;
}
void negative(){
    //ble.print(":("); //DEBUG
    feedback=3;
    feed = true;
}