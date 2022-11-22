/**************************************************************************/
/*!
@file     MQ135.h
@author   G.Krocker (Mad Frog Labs)
@license  GNU GPLv3

First version of an Arduino Library for the MQ135 gas sensor
TODO: Review the correction factor calculation. This currently relies on
the datasheet but the information there seems to be wrong.

@section  HISTORY

v1.0 - First release
*/
/**************************************************************************/
#ifndef MQ135_H
#define MQ135_H
#if ARDUINO >= 100
 #include "Arduino.h"
#else
 #include "WProgram.h"
#endif

/// To convert readed resistance into ohms
#define RLOAD 10.0
/// R0 for AIR
#define r0Air 1
/// R0 for CO **measured with 24hrs of exposure**
#define r0CO 69.65
/// R0 for CO2 **realized 24 hrs of exposure**
//#define r0CO2 553.232 
//#define r0CO2 25.5
#define r0CO2 32.5 // MMMMMMMHHH 
/// R0 for Ethanol **measured with 24hrs of exposure**
#define r0Ethanol 240.293
/// R0 for Ammonium **measured with 24hrs of exposure**
#define r0NH4 164.8282
/// R0 for Toluene **measured with 24hrs of exposure**
#define r0Toluene 130.726
/// R0 for Acetone **measured with 24hrs of exposure**
#define r0Acetone 224.6261
/// Parameters Equation for CO
#define scaleFactorCO 662.9382
#define exponentCO 4.0241
/// Parameters Equation for CO2
#define scaleFactorCO2 116.6020682
#define exponentCO2 2.769034857
///	Paremeters Equation for Ethanol
#define scaleFactorEthanol 75.3103
#define exponentEthanol 3.1459
/// Parameters Equation for NH4
#define scaleFactorNH4 102.694
#define exponentNH4 2.48818
/// Parameters Equation for Toluene
#define scaleFactorToluene 43.7748
#define exponentToluene 3.42936
/// Parameters Equation for Acetone
#define scaleFactorAcetone 33.1197
#define exponentAcetone 3.36587
/// Parameters to model temperature and humidity dependence
#define CORA 0.00035
#define CORB 0.02718
#define CORC 1.39538
#define CORD 0.0018
/// Atmospheric CO Level for calibration purposes
#define atmCO 1
/// Atmospheric CO2 level for calibration purposes
// #define atmCO2 407.57 // 2015
#define atmCO2 415.31 // October 2022
/// Atmospheric Ethanol Level for calibration purposes https://www.mathesongas.com/pdfs/msds/00224106.pdf
#define atmEthanol 22.5
/// Atmospheric NH4 level for calibration purposes
#define atmNH4 15
/// Atmospheric Toluene level for calibration purposes
#define atmToluene 2.9
/// Atmospheric Acetone level for calibration purposes
#define atmAcetone 16


class MQ135 {
 private:
  const uint8_t _pin;

 public:
  MQ135(uint8_t pin);

  void begin();

  float getResistance() const;
  
  float getCOPPM() const;
  float getCO2PPM() const;
  float getEthanolPPM() const;
  float getNH4PPM() const;
  float getToluenePPM() const;
  float getAcetonePPM() const;
  
  float getRZeroCO() const;
  float getRZeroCO2() const;
  float getRZeroEthanol() const;
  float getRZeroNH4() const;
  float getRZeroToluene() const;
  float getRZeroAcetone() const;
  
  float getCO(float res) const;
  float getCO2(float res) const;
  float getEthanol(float res) const;
  float getNH4(float res) const;
  float getToluene(float res) const;
  float getAcetone(float res) const;
  
  
  float getCorrectedRZero(float r) const;
  float getCorrectedRZeroCO(float r) const;
  float getCorrectedRZeroEthanol(float r) const;
  float getCorrectedRZeroNH4(float r) const;
  float getCorrectedRZeroToluene(float r) const;
  float getCorrectedRZeroAcetone(float r) const;
  
  float getCorrectedResistance(float t, float h) const;
  float getCorrectionFactor(float t, float h) const;
  
  float getCalibratedCO2(float t, float h) const;
  float getCalibratedCO(float t, float h) const;
  float getCalibratedEthanol(float t, float h) const;
  float getCalibratedNH4(float t, float h) const;
  float getCalibratedToluene(float t, float h) const;
  float getCalibratedAcetone(float t, float h) const;


};
#endif