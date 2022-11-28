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
#include <dht_nonblocking.h>
#define DHT_SENSOR_TYPE DHT_TYPE_11
static const int DHT_SENSOR_PIN = 5;
DHT_nonblocking dht_sensor( DHT_SENSOR_PIN, DHT_SENSOR_TYPE );
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

unsigned int startMillis;
unsigned int currentMillis;
const unsigned long period = 1000;
float co2;

// A small helper
void error(const __FlashStringHelper*err) {
  Serial.println(err);
  while (1);
}

// TO BE USED ONLY FOR DEV PURPOSE
// TO BE DELETED FOR PRUDUCTION
// IT'S PURPOSE IS TO RETRIEVE CORRECT R0 VALUE FOR CO2
float co2_r0_init(){
  float resistanceZero = mqSensor.getRZeroCO2(); //TEMPORARY!
  return resistanceZero;
}

void ble_setup(){
  //while (!Serial);  // required for Flora & Micro (seems didn't required for Adafruit Feather 32u4 Bluefruit LE)
  //delay(500);

  Serial.begin(115200);
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

  Serial.println("Requesting Bluefruit info:");
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
  pinMode(positiveButtonPin, INPUT);
  pinMode(neutralButtonPin, INPUT);
  pinMode(negativeButtonPin, INPUT);
  //startMillis = millis();
}

/*
 * Poll for a measurement, keeping the state machine alive.  Returns
 * true if a measurement is available.
 */
static bool measure_environment( float *temperature, float *humidity ){
  static unsigned long measurement_timestamp = millis( );

  /* Measure once every four seconds. */
  if( millis( ) - measurement_timestamp > period ){
    if( dht_sensor.measure( temperature, humidity ) == true ){
      co2=analogRead(co2Pin);
      measurement_timestamp = millis( );
      return( true );
    }
  }

  return( false );
}

void loop() {
  // put your main code here, to run repeatedly:
  float temperature;
  float humidity;
  //float co2;

  // read co2
  //co2=analogRead(co2Pin);
  
  // read the state of the pushbutton value:
  feedback_positivo = digitalRead(positiveButtonPin);
  feedback_neutro = digitalRead(neutralButtonPin);
  feedback_negativo = digitalRead(negativeButtonPin);

  /* Measure temperature and humidity.  If the functions returns
     true, then a measurement is available. */
  if( measure_environment( &temperature, &humidity ) == true ){
    float resistance = mqSensor.getResistance();
    co2 = mqSensor.getCO2PPM();
    // TO BE EVALUATED
    //Serial.println("LEggo");
    /*ble.print(0xff); //16 bit for start sequence
		ble.print(0x06); //16 bit for number of paramenters sent
		ble.print((int) temperature); //16 bit for temperature
	  ble.print((int) humidity); //16 bit for humidity
    ble.print((int) co2); //16 bit for co2
    ble.print(feedback_positivo); //16 bit for feedback
    ble.print(feedback_neutro); //16 bit for feedback
    ble.print(feedback_negativo); //16 bit for feedback
    ble.print(co2_r0_init()); //ONLY FOR DEV PURPOSE
		ble.print(0xfe); //16 bit for stop sequence
    //Serial.println(co2_r0_init());
    //feedback=0; //set to 0 after send positive feedback
    feedback_positivo = 0;
    feedback_neutro = 0;
    feedback_negativo = 0;*/
    ble.print(getMsg1((int) temperature,(int) humidity,(int) co2));
    
  }

  //ble.print("ciao");
}
