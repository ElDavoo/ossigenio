/*
/*!
air-quality-monitor
@file     proto1.ino
@author   Antonio Solida
@license  GNU GPLv3
A monitor for air quality, made for IoT and 3D Intelligent Systems @ UniMORE AA 2022-2023.
Please do not divulgate.
v0.1: first Release Candidate (202212041625)
v0.1.1: fixed request messages (20221205)
*/

// start BLE include section
#include <Arduino.h>
#include <SPI.h>
#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_SPI.h"
#include "Adafruit_BluefruitLE_UART.h"
#include "BluefruitConfig.h"
#if SOFTWARE_SERIAL_AVAILABLE
  #include <SoftwareSerial.h>
#endif
#define FACTORYRESET_ENABLE         1
#define MINIMUM_FIRMWARE_VERSION    "0.6.6"
#define MODE_LED_BEHAVIOUR          "MODE"
Adafruit_BluefruitLE_SPI ble(BLUEFRUIT_SPI_CS, BLUEFRUIT_SPI_IRQ, BLUEFRUIT_SPI_RST);
// end BLE section

// start DHT11 include section
#include <DHT.h>
#include <DHT_U.h>
#define DHTTYPE    DHT11
DHT_Unified dht(5, DHTTYPE);
// end DHT11 section

// start FEEDBACK include section
#define positiveButtonPin 2
#define neutralButtonPin 3
#define negativeButtonPin 1
volatile uint8_t feedback = 0; //volatile because this variable is read by interrupt fuctions
// end FEEDBACK include section

// start MQ135 section
#include "MQ135.h"
#define co2Pin A5
MQ135 mqSensor(co2Pin);
// end MQ135 section

// start serial parsing section
#include "serialProtocol.h"
// end serial parsing section

// start stepper section
#include <Servo.h>
Servo myservo;
#define openWindow 180
#define closeWindow 0
// end stepepr section

// start global variables section
#define campTime 1000
int autoSend = 10000;
unsigned long lastExecutedMillis = 0; // to campionate environment datas every 1 sec
unsigned long lastExecutedMillisCount = 0; // to send automatically environment datas every 10 secs
sensors_event_t event;
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

/* 
  TO BE USED ONLY FOR DEV PURPOSE
  TO BE DELETED FOR PRUDUCTION
  IT'S PURPOSE IS TO RETRIEVE CORRECT R0 VALUE FOR CO2
*/
float co2_r0_init(){
  float resistanceZero = mqSensor.getRZeroCO2(); //TEMPORARY!
  return resistanceZero;
}

void ble_setup(){

  Serial.begin(4800);
  Serial.println(F("Adafruit Bluefruit Command <-> Data Mode Example"));
  Serial.println(F("------------------------------------------------"));

  /* Initialise the module */
  Serial.print(F("Initialising the Bluefruit LE module: "));

  if ( !ble.begin(VERBOSE_MODE) ){
    error(F("Couldn't find Bluefruit, make sure it's in CoMmanD mode & check wiring?"));
  }
  Serial.println( F("OK!") );

  if ( FACTORYRESET_ENABLE ){
    /* Perform a factory reset to make sure everything is in a known state */
    Serial.println(F("Performing a factory reset: "));
    if ( ! ble.factoryReset() ){
      error(F("Couldn't factory reset"));
    }
  }
  
  if ( !ble.sendCommandCheckOK(F("AT+GAPDEVNAME=AirQualityMonitor")) ){
    error(F("Couldn't change Bluefruit name :("));
  }
  
  /* Disable command echo from Bluefruit */
  ble.echo(false);

  Serial.println(F("Requesting Bluefruit info:"));
  /* Print Bluefruit information */
  ble.info();

  ble.verbose(false);  // debug info is a little annoying after this point!

  /* Wait for connection */
  /*while (! ble.isConnected()) {
      delay(500);
  }*/

  Serial.println(F("******************************"));

  // LED Activity command is only supported from 0.6.6
  if ( ble.isVersionAtLeast(MINIMUM_FIRMWARE_VERSION) ){
    // Change Mode LED Activity
    Serial.println(F("Change LED activity to " MODE_LED_BEHAVIOUR));
    ble.sendCommandCheckOK("AT+HWModeLED=" MODE_LED_BEHAVIOUR);
  }

  // Set module to DATA mode
  Serial.println( F("Switching to DATA mode!") );
  ble.setMode(BLUEFRUIT_MODE_DATA);

  Serial.println(F("******************************"));
}

void setup() {
  // put your setup code here, to run once:
  ble_setup();
  dht.begin();
  sensor_t sensor;
  myservo.attach(9);  // attaches the servo on pin 9 to the servo object

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

  if (currentMillis - lastExecutedMillis >= campTime) {
    lastExecutedMillis = currentMillis; // save the last executed time
    dht.temperature().getEvent(&event);
    temperature=event.temperature;
    dht.humidity().getEvent(&event);
    humidity=event.relative_humidity;
    co2 = mqSensor.getCO2PPM();
    raw = mqSensor.getResistance();
  }

  //step trigger (ONLY FOR PROTO# FIXED VERSION)
  if (co2 >= 2000) myservo.write(openWindow); //open window
  if (co2 < 2000) myservo.write(closeWindow); //close window

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

}