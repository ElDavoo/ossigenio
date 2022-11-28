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
*/
/**************************************************************************/
#include "serialProtocol.h"

char CRC8(const char *data,int length) {
   char crc = 0x00;
   char extract;
   char sum;
   for(int i=0;i<length;i++){
      extract = *data;
      for (char tempI = 8; tempI; tempI--) {
        sum = (crc ^ extract) & 0x01;
        crc >>= 1;
        if (sum)
           crc ^= 0x8C;
        extract >>= 1;
      }
      data++;
   }
   return crc;
}

char getMsg0(int temp, int humidity, int raw_data){
    //TO BE IMPLEMENTED
}

char getMsg1(int temp, int humidity, int co2) {
    int i;
    char message[4];
    char message_crced[5];

    message[0] = 0xA1;
    message[1] = (temp>>8)  & 0xff;
    message[2] = (humidity>>16) & 0xff;
    message[3] = (co2>>24) & 0xff;
    char crc = CRC8(message,4);
    for(i=0; i<4; i++) message_crced[i]=message[i];
    message_crced[4] = (crc>>32) & 0xff;

    return message_crced;
}

char getMsg3(){
    int i;
    char message[4];
    char message_crced[5];

    message[0] = 0xA3;
    message[1] = (1>>8) & 0xff;
    message[2] = (1>>16) & 0xff;
    message[3] = (0>>24) & 0xff;
    char crc = CRC8(message,4);
    for(i=0; i<4; i++) message_crced[i]=message[i];
    message_crced[4] = (crc>>32) & 0xff;

    return message_crced;
}