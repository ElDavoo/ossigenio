/*
air-quality-monitor (aka Ossigenio)
@file     proto2.ino
@author   Antonio Solida
@license  GNU GPLv3
A monitor for air quality, made for IoT and 3D Intelligent Systems @ UniMORE AA 2022-2023.
Please do not divulgate.
v0.2: first version based on ESP32
*/

// start general include section
#include <Arduino.h>
#include <SPI.h>
#include <stdint.h>
#include <Wire.h>
// end general include section

// start BLE include section
#include "BleSerial.h"
BleSerial ble;
#define ledPin 32
// end BLE section

// start HS3001 include section (temperature and humidity sensor)
#include "HS300x.h"
using namespace HS300x;
cHS300x gHs300x {Wire};
// end HS3001 section

// start FEEDBACK include section
volatile uint8_t feedback = 0; //volatile because this variable is read by interrupt fuctions
volatile bool feed = false; //used to avoid too feedback consecutively
// end FEEDBACK include section

// start CCS811 include section (co2 sensor)
#include "SparkFunCCS811.h"
#define CCS811_ADDR 0x5A //I2C Address (is not hardcoded into library for compatibility purpose)
CCS811 mySensor(CCS811_ADDR);
// end CCS811 include section

// start ens210 include section (temp sensor on board of ccs811 chip; used to monitorate last one warming-up)
#include "ens210.h"
ENS210 ens210;
// end ens210 include section

// start serial parsing section
#include "serialProtocol.h"
// end serial parsing section

// start global variables section
#define campTime 1000
int autoSend = 10000; // autosends env data every 10 seconds
unsigned long lastExecutedMillis = 0; // to campionate environment datas every campTime msec
unsigned long lastExecutedMillisCount = 0; // to send automatically environment datas every 10 secs
float temperature;
float humidity;
float co2;
int raw; //seems not possible to read raw data from ccs811; used for ens210 temperature reading (ccs811 warming-up)
// end global variables section

boolean debug = false; //to enable debug mode

// funzione per il setup del ble
void ble_setup(){
  ble.begin("AirQualityMonitorEBV", true, ledPin); //put ble adv name here //DISABLE IN PRODUCTION
  //ble.begin("Ossigenio", true, ledPin); //ENABLE IN PRODUCTION ONLY
}

void setup() {
  Wire.begin(17,16); //initialize i2c comm
  mySensor.begin(); //initialize ccs811 sensor
  gHs300x.begin(); //initialize gHs3001 sensor
  ble_setup(); //initialize ble

  touchAttachInterrupt(T0, positive, 40); // PIN 4 (on right side)
  touchAttachInterrupt(T2, neutral, 40); // PIN 2 (on right side)
  touchAttachInterrupt(T4, negative, 40); // PIN 13 (on left side)
  // why i'm not using T1? Touch1 >>  Not available on Devkit 30 pin version but available on Devkit 36 pin version
}

void loop() {
  unsigned long currentMillis = millis();
  cHS300x::Measurements m;
  int t_data, t_status, h_data, h_status; //necessary for ens210

  // it reads enviroment data from sensors every CampTime seconds
  if (currentMillis - lastExecutedMillis >= campTime) {
    lastExecutedMillis = currentMillis; // save the last executed time

    // temperature and humidity section
    if (gHs300x.getTemperatureHumidity(m)){
      m.extract(temperature, humidity); // read temperature and humidity values
    }

    // co2 section (read also co2 sensor temperature for reliability purpose)
    if (mySensor.dataAvailable()) {
      mySensor.readAlgorithmResults();
      co2 = (float) mySensor.getCO2(); // read co2 value
      ens210.measure(&t_data, &t_status, &h_data, &h_status ); //see after comment
      raw = (int) ens210.toCelsius(t_data,10)/10.0; //temperature of co2 sensor
    }
    feed = false; //re-enabling feedback disabled into isr
  }

  // feedback interrupt result management
  if ((feedback == 1 || feedback == 2 || feedback == 3) && feed == false) {
    getMsg4((int) temperature,(int) humidity,(int) co2, feedback);
    feedback = 0;
  }
  
  // ble read section
  uint8_t buf[4] = {0x00,0x00,0x00,0x00};
  while (ble.available() > 0){
    int rlen = ble.readBytes(buf, 4); //read 4 bytes from seruak
  }

  unsigned long currentMillisCount = millis();
   //sends a message with sensor data over ble every autoSend seconds
  if (currentMillisCount - lastExecutedMillisCount >= autoSend){
    lastExecutedMillisCount = currentMillisCount;
    getMsg1((int) temperature,(int) humidity,(int) co2);
  }
  /*
  For other types of messages, proto2 will wait for external input and sends they
  according to it.
  */
  if(buf[0] == 0xAA && buf[2] == 0xFF){
    switch(buf[1]){
      case 0x1F: //AA1FFF MESSAGE
        //environment temperature, humidity and co2 sensor temperature
        getMsg0((int) temperature, (int) humidity, raw);
        break;

      case 0x1E: //AA1EFF MESSAGE
        //environment temperature, humidity and co2
        getMsg1((int) temperature,(int) humidity,(int) co2);
        break;

      case 0x1C: //AA1CFF MESSAGE
        //model, version, serial number and battery value
        getMsg3();
        break;

      case 0x1B: //AA1BFF MESSAGE (trigger debug mode activation)
        feedback = 123;
        //environment temperature, humidity, co2 and feedback placeholder value
        getMsg4((int) temperature,(int) humidity,(int) co2, feedback);
        feedback = 0;
        debug = !debug; // enable/disable debug mode
        if (debug == true) {
          ble.print("Debug mode enabled.");
          //enabling debug mode, it sends automatically data every seconds instead of 10 seconds
          autoSend = 1000;
        }
        else {
          ble.print("Debug mode disabled.");
          autoSend = 10000;
        }
        break;
    }
  }
}