/*
  ens210.cpp - Library for the ENS210 relative humidity and temperature sensor with I2C interface from ams
  2018 Oct 23  v2  Maarten Pennings  Improved begin()
  2017 Aug  2  v1  Maarten Pennings  Created
*/

#include <assert.h>
#include <Arduino.h>
#include <Wire.h>
#include "ens210.h"


// begin() prints errors to help diagnose startup problems.
// Change these macro's to empty to suppress those prints.
#define PRINTLN Serial.println
#define PRINT   Serial.print
#define PRINTF  Serial.printf


// Chip constants
#define ENS210_PARTID          0x0210 // The expected part id of the ENS210
#define ENS210_BOOTING_MS           2 // Booting time in ms (also after reset, or going to high power)

// Addresses of the ENS210 registers
#define ENS210_REG_PART_ID       0x00
#define ENS210_REG_UID           0x04
#define ENS210_REG_SYS_CTRL      0x10
#define ENS210_REG_SYS_STAT      0x11
#define ENS210_REG_SENS_RUN      0x21
#define ENS210_REG_SENS_START    0x22
#define ENS210_REG_SENS_STOP     0x23
#define ENS210_REG_SENS_STAT     0x24
#define ENS210_REG_T_VAL         0x30
#define ENS210_REG_H_VAL         0x33

// Division macro (used in conversion functions), implementing integer division with rounding.
// It supports both positive and negative dividends (n), but ONLY positive divisors (d).
#define IDIV(n,d)                ((n)>0 ? ((n)+(d)/2)/(d) : ((n)-(d)/2)/(d))


//               7654 3210
// Polynomial 0b 1000 1001 ~ x^7+x^3+x^0
//            0x    8    9
#define CRC7WIDTH  7    // A 7 bits CRC has polynomial of 7th order, which has 8 terms
#define CRC7POLY   0x89 // The 8 coefficients of the polynomial
#define CRC7IVEC   0x7F // Initial vector has all 7 bits high
// Payload data
#define DATA7WIDTH 17
#define DATA7MASK  ((1UL<<DATA7WIDTH)-1) // 0b 0 1111 1111 1111 1111
#define DATA7MSB   (1UL<<(DATA7WIDTH-1)) // 0b 1 0000 0000 0000 0000
// Compute the CRC-7 of 'val' (should only have 17 bits)
// https://en.wikipedia.org/wiki/Cyclic_redundancy_check#Computation
static uint32_t crc7( uint32_t val ) {
  // Setup polynomial
  uint32_t pol= CRC7POLY;
  // Align polynomial with data
  pol = pol << (DATA7WIDTH-CRC7WIDTH-1);
  // Loop variable (indicates which bit to test, start with highest)
  uint32_t bit = DATA7MSB;
  // Make room for CRC value
  val = val << CRC7WIDTH;
  bit = bit << CRC7WIDTH;
  pol = pol << CRC7WIDTH;
  // Insert initial vector
  val |= CRC7IVEC;
  // Apply division until all bits done
  while( bit & (DATA7MASK<<CRC7WIDTH) ) {
    if( bit & val ) val ^= pol;
    bit >>= 1;
    pol >>= 1;
  }
  return val;
}


// Resets ENS210 and checks its PART_ID. Returns false on I2C problems or wrong PART_ID.
// Stores solder correction.
bool ENS210::begin(void) {
  bool ok;
  uint16_t partid;
  // Record solder correction
  _soldercorrection= 0;
  // Reset
  ok= reset();  
  if( !ok ) ok= reset(); // Retry
  if( !ok ) { PRINTLN("ens210: begin: reset failed (ENS210 connected? Wire.begin called?)"); return false; }
  // Get partid
  ok= getversion(&partid,NULL); 
  if( !ok ) { PRINTLN("ens210: begin: getversion failed"); return false; }
  // Check partid
  if( partid!=ENS210_PARTID ) { PRINT("ens210: begin: PARTID mismatch: "); PRINTLN(partid,HEX); return false; }
  // Success
  return true;
}


// Performs one single shot temperature and relative humidity measurement.
void ENS210::measure(int * t_data, int * t_status, int * h_data, int * h_status ) {
  bool ok;
  uint32_t t_val;
  uint32_t h_val;
  // Set default status for early bail out
  *t_status= ENS210_STATUS_I2CERROR;
  *h_status= ENS210_STATUS_I2CERROR;
  // Start a single shot measurement
  ok= startsingle(); if(!ok) return; // Both statuses have value ENS210_STATUS_I2CERROR
  // Wait for measurement to complete
  delay(ENS210_THCONV_SINGLE_MS);
  // Get the measurement data
  ok= read(&t_val,&h_val); if(!ok) return;  // Both statuses have value ENS210_STATUS_I2CERROR
  // Extract the data and update the statuses
  extract(t_val, t_data, t_status);
  extract(h_val, h_data, h_status);
}


// Sends a reset to the ENS210. Returns false on I2C problems.
bool ENS210::reset(void) {
  Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
  Wire.write(ENS210_REG_SYS_CTRL);         // Register address (SYS_CTRL)
  Wire.write(0x80);                        // SYS_CTRL: reset
  int result= Wire.endTransmission();      // STOP
  //PRINTF("ens210: debug: reset %d\n",result);
  delay(ENS210_BOOTING_MS);                // Wait to boot after reset
  return result==0;
}


// Sets ENS210 to low (true) or high (false) power. Returns false on I2C problems.
bool ENS210::lowpower(bool enable) {
  uint8_t power = enable ? 0x01: 0x00;
  Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
  Wire.write(ENS210_REG_SYS_CTRL);         // Register address (SYS_CTRL)
  Wire.write(power);                       // SYS_CTRL: power
  int result= Wire.endTransmission();      // STOP
  //PRINTF("ens210: debug: lowpower(%d) %d\n",power,result); // 0:success, 1:data-too-long, 2:NACK-on-addr, 3:NACK-on-data, 4:other
  delay(ENS210_BOOTING_MS);                // Wait boot-time after power switch
  return result==0;
}


// Reads PART_ID and UID of ENS210. Returns false on I2C problems.
bool ENS210::getversion(uint16_t*partid,uint64_t*uid) {
  bool ok;
  uint8_t i2cbuf[2];
  int result;

  // Must disable low power to read PART_ID or UID
  ok= lowpower(false); if(!ok) goto errorexit;

  // Read the PART_ID
  if( partid!=0 ) {
    Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
    Wire.write(ENS210_REG_PART_ID);          // Register address (PART_ID); using auto increment
    result= Wire.endTransmission(false);     // Repeated START
    Wire.requestFrom(_slaveaddress,2);       // From ENS210, read 2 bytes, STOP
    //PRINTF("ens210: debug: getversion/part_id %d\n",result);
    if( result!=0 ) goto errorexit;
    // Retrieve and pack bytes into partid
    for( int i=0; i<2; i++ ) i2cbuf[i]= Wire.read();
    *partid= i2cbuf[1]*256U + i2cbuf[0]*1U;
  }

  // Read the UID
  if( uid!=0 ) {
    Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
    Wire.write(ENS210_REG_UID);              // Register address (UID); using auto increment
    result= Wire.endTransmission(false);     // Repeated START
    Wire.requestFrom(_slaveaddress,8);       // From ENS210, read 8 bytes, STOP
    //PRINTF("ens210: debug: getversion/uid %d\n",result);
    if( result!=0 ) goto errorexit;
    // Retrieve and pack bytes into uid (ignore the endianness)
    for( int i=0; i<8; i++) ((uint8_t*)uid)[i]=Wire.read();
  }

  // Go back to default power mode (low power enabled)
  ok= lowpower(true); if(!ok) goto errorexit;

  // { uint32_t hi= *uid >>32, lo= *uid & 0xFFFFFFFF; PRINTF("ens210: debug: PART_ID=%04x UID=%08x %08x\n",*partid,hi,lo); }
  // Success
  return true;

errorexit:
  // Try to go back to default mode (low power enabled)
  ok= lowpower(true);
  // Hopefully enabling low power was successful; but there was an error before that anyhow
  return false;
}


// Configures ENS210 to perform a single measurement. Returns false on I2C problems.
bool ENS210::startsingle(void) {
  Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
  Wire.write(ENS210_REG_SENS_RUN);         // Register address (SENS_RUN); using auto increment
  Wire.write(0x00);                        // SENS_RUN  : T_RUN=0/single , H_RUN=0/single
  Wire.write(0x03);                        // SENS_START: T_START=1/start, H_START=1/start
  int result= Wire.endTransmission();      // STOP
  //PRINTF("ens210: debug: startsingle %d\n",result);
  return result==0;
}


// Configures ENS210 to switch to continuous measurement. Returns false on I2C problems.
bool ENS210::startcont(void) {
  Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
  Wire.write(ENS210_REG_SENS_RUN);         // Register address (SENS_RUN); using auto increment
  Wire.write(0x03);                        // SENS_RUN  : T_RUN=1/cont , H_RUN=1/cont
  Wire.write(0x03);                        // SENS_START: T_START=1/start, H_START=1/start
  int result= Wire.endTransmission();      // STOP
  //PRINTF("ens210: debug: startcont %d\n",result);
  return result==0;
}


// Configures ENS210 to stop continuous measurement. Returns false on I2C problems.
bool ENS210::stopcont(void) {
  Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
  Wire.write(ENS210_REG_SENS_STOP);        // Register address (SENS_STOP)
  Wire.write(0x03);                        // SENS_START: T_STOP=1/start, H_STOP=1/start
  int result= Wire.endTransmission();      // STOP
  //PRINTF("ens210: debug: stopcont %d\n",result);
  return result==0;
}


// Reads measurement data from the ENS210. Returns false on I2C problems.
bool ENS210::read(uint32_t *t_val, uint32_t *h_val) {
  uint8_t i2cbuf[6];
  // Read T_VAL and H_VAL
  Wire.beginTransmission(_slaveaddress);   // START, SLAVEADDR
  Wire.write(ENS210_REG_T_VAL);            // Register address (T_VAL); using auto increment (up to H_VAL)
  int result= Wire.endTransmission(false); // Repeated START
  Wire.requestFrom(_slaveaddress,6);       // From ENS210, read 6 bytes, STOP
  //PRINTF("ens210: debug: read %d\n",result);
  if( result!=0 ) return false;
  // Retrieve and pack bytes into t_val and h_val
  for( int i=0; i<6; i++ ) i2cbuf[i]= Wire.read();
  *t_val= (i2cbuf[2]*65536UL) + (i2cbuf[1]*256UL) + (i2cbuf[0]*1UL);
  *h_val= (i2cbuf[5]*65536UL) + (i2cbuf[4]*256UL) + (i2cbuf[3]*1UL);
  // Range checking
  //PRINTF("ens210: debug: read T=%06x H=%06x\n",*t_val,*h_val);
  //if( *t_val<(273-100)*64 || *t_val>(273+150)*64 ) return false; // Accept only readouts -100<=T_in_C<=+150 (arbitrary limits)
  //if( *h_val>100*512 ) return false; // Accept only readouts 0<=H<=100
  // Success
  return true;
}


// Reads measurement data from the ENS210 and extracts data and status.
void ENS210::read(int*t_data,int*t_status,int*h_data,int*h_status) {
  uint32_t t_val;
  uint32_t h_val;
  // Get the measurement data
  bool ok=read(&t_val,&h_val);
  if( !ok ) {
    // Signal I2C error
    *t_status= ENS210_STATUS_I2CERROR;
    *h_status= ENS210_STATUS_I2CERROR;
  } else {
    // Extract the data and update the statuses
    extract(t_val, t_data, t_status);
    extract(h_val, h_data, h_status);
  } 
}


// Extracts measurement `data` and `status` from a `val` obtained from `read`.
// Upon entry, 'val' is the 24 bits read from T_VAL or H_VAL.
// Upon exit, 'data' is the T_DATA or H_DATA, and 'status' one of ENS210_STATUS_XXX.
void ENS210::extract(uint32_t val, int * data, int * status) {
  // Destruct 'val'
  * data           = (val>>0 ) & 0xffff;
  int valid        = (val>>16) & 0x1;
  uint32_t crc     = (val>>17) & 0x7f;
  uint32_t payload = (val>>0 ) & 0x1ffff;
  int crc_ok= crc7(payload)==crc;
  // Check CRC and valid bit
  if( !crc_ok ) *status= ENS210_STATUS_CRCERROR;
  else if( !valid ) *status= ENS210_STATUS_INVALID;
  else *status= ENS210_STATUS_OK;
}


// Converts a status (ENS210_STATUS_XXX) to a human readable string.
const char * ENS210::status_str( int status ) {
  switch( status ) {
    case ENS210_STATUS_I2CERROR : return "i2c-error";
    case ENS210_STATUS_CRCERROR : return "crc-error";
    case ENS210_STATUS_INVALID  : return "data-invalid";
    case ENS210_STATUS_OK       : return "ok";
    default                     : return "unknown-status";
  }
}


// Convert raw `t_data` temperature to Kelvin (also applies the solder correction).
// The output value is in Kelvin multiplied by parameter `multiplier`.
int32_t ENS210::toKelvin(int t_data, int multiplier) {
  assert( (1<=multiplier) && (multiplier<=1024) );
  // Force 32 bits
  int32_t t= t_data & 0xFFFF;
  // Compensate for soldering effect
  t-= _soldercorrection;
  // Return m*K. This equals m*(t/64) = (m*t)/64
  // Note m is the multiplier, K is temperature in Kelvin, t is raw t_data value.
  // Uses K=t/64.
  return IDIV(multiplier*t,64);
}


// Convert raw `t_data` temperature to Celsius (also applies the solder correction).
// The output value is in Celsius multiplied by parameter `multiplier`.
int32_t ENS210::toCelsius(int t_data, int multiplier) {
  assert( (1<=multiplier) && (multiplier<=1024) );
  // Force 32 bits
  int32_t t= t_data & 0xFFFF;
  // Compensate for soldering effect
  //t-= _soldercorrection;
  // Return m*C. This equals m*(K-273.15) = m*K - 27315*m/100 = m*t/64 - 27315*m/100
  // Note m is the multiplier, C is temperature in Celsius, K is temperature in Kelvin, t is raw t_data value.
  // Uses C=K-273.15 and K=t/64.
  return IDIV(multiplier*t,64) - IDIV(27315L*multiplier,100);
}


// Convert raw `t_data` temperature to Fahrenheit (also applies the solder correction).
// The output value is in Fahrenheit multiplied by parameter `multiplier`.
int32_t ENS210::toFahrenheit(int t_data, int multiplier) {
  assert( (1<=multiplier) && (multiplier<=1024) );
  // Force 32 bits
  int32_t t= t_data & 0xFFFF;
  // Compensate for soldering effect
  t-= _soldercorrection;
  // Return m*F. This equals m*(1.8*(K-273.15)+32) = m*(1.8*K-273.15*1.8+32) = 1.8*m*K-459.67*m = 9*m*K/5 - 45967*m/100 = 9*m*t/320 - 45967*m/100
  // Note m is the multiplier, F is temperature in Fahrenheit, K is temperature in Kelvin, t is raw t_data value.
  // Uses F=1.8*(K-273.15)+32 and K=t/64.
  return IDIV(9*multiplier*t,320) - IDIV(45967L*multiplier,100);
  // The first multiplication stays below 32 bits (t:16, multiplier:11, 9:4)
  // The second multiplication stays below 32 bits (multiplier:10, 45967:16)
}


// Convert raw `h_data` relative humidity to %RH.
// The output value is in %RH multiplied by parameter `multiplier`.
int32_t ENS210::toPercentageH(int h_data, int multiplier) {
  assert( (1<=multiplier) && (multiplier<=1024) );
  // Force 32 bits
  int32_t h= h_data & 0xFFFF;
  // Return m*H. This equals m*(h/512) = (m*h)/512
  // Note m is the multiplier, H is the relative humidity in %RH, h is raw h_data value.
  // Uses H=h/512.
  return IDIV(multiplier*h, 512);
}


// Sets the solder correction (default is 50mK) - only used by the `toXxx` functions.
void ENS210::correction_set(int correction) {
  assert( -1*64<correction && correction<+1*64 ); // A correction of more than 1 Kelvin does not make sense (but the 1K is arbitrary)
  _soldercorrection = correction;
}


// Gets the solder correction
int ENS210::correction_get(void) {
  return _soldercorrection;
}

