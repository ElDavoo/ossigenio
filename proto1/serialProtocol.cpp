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
    /*
    ble.print(0xA1); //START SEQUENCE
	ble.print(0x06); //LENGTH OF MESSAGE
	ble.print(temp); //TEMPERATURE
	ble.print(humidity); //HUMIDITY
    ble.print(co2); //CO2
	ble.print(); //CRC8
    */
    
}