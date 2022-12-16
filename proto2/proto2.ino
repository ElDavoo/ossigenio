/*
/*!
air-quality-monitor
@file     proto2.ino
@author   Antonio Solida
@license  GNU GPLv3
A monitor for air quality, made for IoT and 3D Intelligent Systems @ UniMORE AA 2022-2023.
Please do not divulgate.
v0.2: first version based on ESP32
*/

#include <Arduino.h>
#include <SPI.h>
#include <stdint.h>

// start BLE include section
#include "BleSerial.h"
BleSerial ble;
// end BLE section

// start DHT11 include section
#include "HS300x.h"
using namespace HS300x;
cHS300x gHs300x {Wire};
// end DHT11 section

// start FEEDBACK include section
#define positiveButtonPin 2
#define neutralButtonPin 3
#define negativeButtonPin 1
volatile uint8_t feedback = 0; //volatile because this variable is read by interrupt fuctions
// end FEEDBACK include section

// start MQ135 section
#include <Wire.h>
#include "SparkFunCCS811.h"
#define CCS811_ADDR 0x5A //Alternate I2C Address
CCS811 mySensor(CCS811_ADDR);
// end MQ135 section

// start serial parsing section
#include "serialProtocol.h"
// end serial parsing section

// start global variables section
#define campTime 1000
int autoSend = 10000;
unsigned long lastExecutedMillis = 0; // to campionate environment datas every 1 sec
unsigned long lastExecutedMillisCount = 0; // to send automatically environment datas every 10 secs
float temperature;
float humidity;
float co2;
int raw;
// end global variables section

boolean debug = false; //to enable debug mode

// A small helper
void error(const __FlashStringHelper*err) {
  Serial.println(err);
  while (1);
}

void ble_setup(){
  ble.begin("AirQualityMonitor");
  //Serial.println("ESP32 Bluetooth");
}

void setup() {
  // put your setup code here, to run once:
  Wire.begin(17,16);
  mySensor.begin();
  gHs300x.begin();
  ble_setup();

  pinMode(positiveButtonPin, INPUT);
  pinMode(neutralButtonPin, INPUT);
  pinMode(negativeButtonPin, INPUT);
  attachInterrupt(1, positive, RISING); //INT1 ASSOCIATO AL PIN 2 -> positiveButtonPin
  attachInterrupt(0, neutral, RISING); //INT0 ASSOCIATO AL PIN 3 -> neutralButtonPin
  attachInterrupt(3, negative, RISING); //INT3 ASSOCIATO AL PIN 1 -> negativeButtonPin
}

void loop() {
  // put your main code here, to run repeatedly:
  unsigned long currentMillis = millis();
  cHS300x::Measurements m;

  if (currentMillis - lastExecutedMillis >= campTime) {
    lastExecutedMillis = currentMillis; // save the last executed time
    if (gHs300x.getTemperatureHumidity(m)){
      m.extract(temperature, humidity);
    }
    if (mySensor.dataAvailable()) {
      mySensor.readAlgorithmResults();
      co2 = (float) mySensor.getCO2();
      raw = mySensor.getBaseline();
    }
  }

  // feedback interrupt result management
  if (feedback == 1 || feedback == 2 || feedback == 3) {
    getMsg4((int) temperature,(int) humidity,(int) co2, feedback);
    feedback = 0;
  }
  
  // ble read section
  //String c = ble.readString();
  uint8_t buf[4] = {0x00,0x00,0x00,0x00};
  while (ble.available() > 0){
    int rlen = ble.readBytes(buf, 4);
    ble.write(buf[0]);
  }
  unsigned long currentMillisCount = millis();
  if (currentMillisCount - lastExecutedMillisCount >= autoSend){
    lastExecutedMillisCount = currentMillisCount;
    getMsg1((int) temperature,(int) humidity,(int) co2);
  }
  /*
  For other types of messages, proto1 will wait for external input and sends they
  according to it.
  */
  if(buf[0] == 0xAA && buf[2] == 0xFF){
    switch(buf[1]){
      case 0x1F:
        getMsg0((int) temperature, (int) humidity, raw);
        break;

      case 0x1E:
        getMsg1((int) temperature,(int) humidity,(int) co2);
        break;

      case 0x1C:
        getMsg3();
        break;

      case 0x1B:
        feedback = 123;
        getMsg4((int) temperature,(int) humidity,(int) co2, feedback);
        feedback = 0;
        debug = !debug; // enable/disable debug mode
        if (debug == true) {
          ble.print("Debug mode enabled.");
          autoSend = 1000;
        }
        else {
          ble.print("Debug mode disabled.");
          autoSend = 10000;
        }
        break;
    }
  }


  /*if (buf[3] == 'F') {
    getMsg0((int) temperature, (int) humidity, raw);
  }
  if (buf[3] == 'E' || watchDog[0] == 'E') {
    getMsg1((int) temperature,(int) humidity,(int) co2);
  }
  if (buf[3] == 'C') getMsg3(); //VERSION MESSAGE
  if (buf[3] == 'B') { //forced sending feedback message -- Debug purpose only
    feedback = 123;
    getMsg4((int) temperature,(int) humidity,(int) co2, feedback);
    feedback = 0;
    debug = !debug; // enable/disable debug mode
    if (debug == true) ble.print("Debug mode enabled.");
    else ble.print("Debug mode disabled.");
  }*/
  //if(debug == true) ble.print("Check!"); //ONLY FOR DEBUG PURPOSE!

}