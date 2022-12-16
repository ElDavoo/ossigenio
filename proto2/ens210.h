/*
  ens210.h - Library for the ENS210 relative humidity and temperature sensor with I2C interface from ams
  Created by Maarten Pennings 2017 Aug 1
*/
#ifndef __ENS210_H_
#define __ENS210_H_


#include <stdint.h>


// Measurement status as output by `measure()` and `extract()`.
// Note that the ENS210 provides a "value" (`t_val` or `h_val` each 24 bit).
// A "value" consists of a payload (17 bit) and a CRC (7 bit) over that payload.
// The payload consists of a valid flag (1 bit) and the actual measurement "data" (`t_data` or `h_data`, 16 bit)
#define ENS210_STATUS_I2CERROR    4 // There was an I2C communication error, `read`ing the value.
#define ENS210_STATUS_CRCERROR    3 // The value was read, but the CRC over the payload (valid and data) does not match.
#define ENS210_STATUS_INVALID     2 // The value was read, the CRC matches, but the data is invalid (e.g. the measurement was not yet finished).
#define ENS210_STATUS_OK          1 // The value was read, the CRC matches, and data is valid.

// Chip constants
#define ENS210_THCONV_SINGLE_MS 130 // Conversion time in ms for single shot T/H measurement
#define ENS210_THCONV_CONT_MS   238 // Conversion time in ms for continuous T/H measurement

class ENS210 {
  public: // Main API functions
    // Resets ENS210 and checks its PART_ID. Returns false on I2C problems or wrong PART_ID.
    bool begin(void);
    // Performs one single shot temperature and relative humidity measurement.
    // Sets `t_data` (temperature in 1/64K), and `t_status` (from ENS210STATUS_XXX).
    // Sets `h_data` (relative humidity in 1/512 %RH), and `h_status` (from ENS210STATUS_XXX).
    // Use the conversion functions below to convert `t_data` to K, C, F; or `h_data` to %RH.
    // Note that this function contains a delay of 130ms to wait for the measurement to complete.
    // If you don't want that, use startsingle() ... wait ENS210_THCONVERSION_MS ... read(). 
    void measure(int * t_data, int * t_status, int * h_data, int * h_status );

  public: // Conversion functions - the temperature conversions also subtract the solder correction (see correction_set() method).
    int32_t toKelvin     (int t_data, int multiplier);          // Converts t_data (from `measure`) to 1/multiplier Kelvin
    int32_t toCelsius    (int t_data, int multiplier);          // Converts t_data (from `measure`) to 1/multiplier Celsius
    int32_t toFahrenheit (int t_data, int multiplier);          // Converts t_data (from `measure`) to 1/multiplier Fahrenheit
    int32_t toPercentageH(int h_data, int multiplier);          // Converts h_data (from `measure`) to 1/multiplier %RH

    // Optionally set a solder `correction` (units: 1/64K, default from `begin` is 0).
    // See "Effect of Soldering on Temperature Readout" in "Design-Guidelines" from
    // https://download.ams.com/ENVIRONMENTAL-SENSORS/ENS210/Documentation
    void correction_set(int correction=50*64/1000);             // Sets the solder correction (default is 50mK) - only used by the `toXxx()` functions.
    int  correction_get(void);                                  // Gets the solder correction.
                                                                
  public: // Helper functions (communicating with ENS210)       
    bool reset(void);                                           // Sends a reset to the ENS210. Returns false on I2C problems.
    bool lowpower(bool enable);                                 // Sets ENS210 to low (true) or high (false) power. Returns false on I2C problems.
    bool getversion(uint16_t*partid,uint64_t*uid);              // Reads PART_ID and UID of ENS210. Returns false on I2C problems.
    bool startsingle(void);                                     // Configures ENS210 to perform one single shot measurement. Returns false on I2C problems.
    bool startcont(void);                                       // Configures ENS210 to switch to continuous measurement. Returns false on I2C problems.
    bool stopcont(void);                                        // Configures ENS210 to stop continuous measurement. Returns false on I2C problems.
    bool read(uint32_t*t_val,uint32_t*h_val);                   // Reads measurement data from the ENS210. Returns false on I2C problems.
    void read(int*t_data,int*t_status,int*h_data,int*h_status); // Reads measurement data from the ENS210 and extracts data and status.

  public: // Helper functions (data conversion)
    static void extract(uint32_t val,int*data,int*status);      // Extracts measurement `data` and `status` from a `val` obtained from `read()`.
    static const char * status_str( int status );               // Converts a status (ENS210_STATUS_XXX) to a human readable string.
                                                                
  protected: // Data members                                    
    int  _slaveaddress= 0x43;                                   // Slave address of ENS210
    int  _soldercorrection;                                     // Correction due to soldering (in 1/64K); subtracted from `t_data` by conversion functions.
};


#endif
