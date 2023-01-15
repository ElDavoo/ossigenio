/*
Header file for stepper control.
Used by proto2.ino in fixed version.
*/

#ifndef STEP_H_
#define STEP_H_ 

#include <Stepper.h>
const int stepsPerRevolution = 2048;  // steps per revolution
// ULN2003 Motor Driver Pins
#define IN1 19
#define IN2 18
#define IN3 5
#define IN4 17
Stepper myStepper(stepsPerRevolution, IN1, IN3, IN2, IN4); // initialize the stepper library
#define stepsOpen 1024 //steps to open window

#endif