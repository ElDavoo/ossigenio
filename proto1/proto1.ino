/*
/*!
air-quality-monitor
@file     proto1.ino
@author   Antonio Solida
@license  GNU GPLv3
A monitor for air quality, made for IoT and 3D Intelligent Systems @ UniMORE AA 2022-2023.
Please do not divulgate.
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
uint32_t delayMS;
// end DHT11 section

// start FEEDBACK include section
#define positiveButtonPin 2
#define neutralButtonPin 3
#define negativeButtonPin 6
int feedback_positivo = 0;
int feedback_neutro = 0;
int feedback_negativo = 0;
// end FEEDBACK include section

// start MQ135 section
#include "MQ135.h"
int co2Pin = A5;
MQ135 mqSensor(co2Pin);
// end MQ135 section

// start serial parsing section
#include "serialProtocol.h"
// end serial parsing section

//unsigned long startMillis;
//unsigned long currentMillis;
//const unsigned long period = 10000;
int count=0;
float co2;

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
  //while (!Serial);  // required for Flora & Micro (seems didn't required for Adafruit Feather 32u4 Bluefruit LE)
  //delay(500);

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

  /* Disable command echo from Bluefruit */
  ble.echo(false);

  Serial.println(F("Requesting Bluefruit info:"));
  /* Print Bluefruit information */
  ble.info();

  //Serial.println(F("Please use Adafruit Bluefruit LE app to connect in UART mode"));
  //Serial.println(F("Then Enter characters to send to Bluefruit"));
  //Serial.println();

  ble.verbose(false);  // debug info is a little annoying after this point!

  /* Wait for connection */
  while (! ble.isConnected()) {
      delay(500);
  }

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
  //Serial.begin(9600);
  ble_setup();
  dht.begin();
  sensor_t sensor;
  delayMS = sensor.min_delay / 1000;
  pinMode(positiveButtonPin, INPUT);
  pinMode(neutralButtonPin, INPUT);
  pinMode(negativeButtonPin, INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  float temperature;
  float humidity;
  sensors_event_t event;
  delay(delayMS / 1000);
  /*dht.temperature().getEvent(&event);
  //dht.humidity().getEvent(&event);
  temperature=event.temperature;
  dht.humidity().getEvent(&event);
  humidity=event.relative_humidity;
  getMsg1((int) temperature,(int) humidity,(int) co2);*/

  // read the state of the pushbutton value:
  feedback_positivo = digitalRead(positiveButtonPin);
  feedback_neutro = digitalRead(neutralButtonPin);
  feedback_negativo = digitalRead(negativeButtonPin);
  // WHEN one of the feedback buttons will be equal to HIGH, proto1 will send feedback message
  // along with ambiental data
  // PLACEHOLDER
  // SECTION WORK IN PROGRESS
  //
  //
  //
  //
  String c = ble.readString();
  count++;
  //ble.print(count);
  if(count >= 30) {
    c='e';
    count=0;
  }
  /*
  For other types of messages, proto1 will wait for external input and sends they
  according to it.
  */
  // PLACEHOLDER
  // SECTION WORK IN PROGRESS
  //
  if (c.charAt(0) == 'f') {
    dht.temperature().getEvent(&event);
    temperature=event.temperature;
    dht.humidity().getEvent(&event);
    humidity=event.relative_humidity;
    int raw = mqSensor.getResistance();
    getMsg0((int) temperature, (int) humidity, raw);
  }
  if (c.charAt(0) == 'e') {
    dht.temperature().getEvent(&event);
    temperature=event.temperature;
    dht.humidity().getEvent(&event);
    humidity=event.relative_humidity;
    co2 = mqSensor.getCO2PPM();
    getMsg1((int) temperature,(int) humidity,(int) co2);
  }
  if (c.charAt(0) == 'c') getMsg3(); //VERSION MESSAGE
  //
  //

  /*
  In this section proto1 will send measurement data every 30 seconds
  For dev purpose, now it sends every second
  */
  /*if( measure_environment( &temperature, &humidity ) == true ){
    float resistance = mqSensor.getResistance();
    co2 = mqSensor.getCO2PPM();
    //feedback_positivo = 0; //DEPRECATED
    //feedback_neutro = 0; //DEPRECATED
    //feedback_negativo = 0; //DEPRECATED
    getMsg1((int) temperature,(int) humidity,(int) co2);
    
  }*/
  // EXPERIMENTAL! Millis() and micros() seembs broken here; we won't use they :|
  //currentMillis = micros();
  /*if( count>=30 ){
    delay(delayMS / 1000);
    dht.temperature().getEvent(&event);
    temperature=event.temperature;
    dht.humidity().getEvent(&event);
    humidity=event.relative_humidity;
    co2 = mqSensor.getCO2PPM();
    getMsg1((int) temperature,(int) humidity,(int) co2);
    count=0;
  } else count++;*/
}
