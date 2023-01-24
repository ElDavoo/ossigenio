# Technical documentation of prototype proto1
First prototype developed and based upon Adafruit Feather 32u4 board; chosen because of low cost and compatibility with the Arduino development environment.
Discarded later because of low performance and unreliability of sensors, particularly the carbon dioxide sensor. It is currently relegated for the fixed version.

![Imgur](https://user-images.githubusercontent.com/4050967/214252089-7a0dd76d-0b9c-47e1-b565-18e969a560d7.jpg)

## Firmware development
Due to Arduino compatibility, this environment was used for its development. Software requirements are available on [Requirements.md](/doc/Requirements.md).
The BLE part is based on the Nordic nrf51 chip, consequently, custom libraries from Adafruit were used which based, in turn, on the libraries of the RF chip. They provide serial-type communication similar in operation to the common UART.
A special communication protocol was implemented to ensure reliable communication between the prototype and the bridge (smartphone); see [SerialProtocol.md](/doc/SerialProtocol.md) for details.

## Sensors chosen
For environmental data sampling, we chose these sensors:
* [DHT11](/doc/DHT11-Datasheet.pdf) (temperature and humidity);
* [MQ135](/doc/MQ135-datasheet.pdf) (carbon dioxide).
In particular MQ135 did not seem to be very reliable and was one of the main reasons in which alternatives were sought.

## Window actuator
As it is relegated to the fixed version, it semicompletely demonstrates the operation of a carbon dioxide controller that, when carbon dioxide rises above a certain value, drives a servomotor to open a window and then to close it. Given its demonstrative nature, no further functionality was chosen to be implemented.

## Data reading
Communication with and reading from sensors is possible through the *digitalRead()* and *analogRead()* functions; these were not used directly because the relevant sensor libraries provided a higher-level interface.
```c
// used millis() function
if (currentMillis - lastExecutedMillis >= campTime) { // with campTime normally equal to 10 seconds
    lastExecutedMillis = currentMillis; // save the last executed time
    dht.temperature().getEvent(&event);
    temperature=event.temperature;
    dht.humidity().getEvent(&event);
    humidity=event.relative_humidity;
    co2 = mqSensor.getCO2PPM();
    raw = mqSensor.getResistance();
  }
```

## Wiring diagram
See [proto1_wiring_diagram.pdf](/doc/proto1_wiring_diagram.pdf). See also [Adafruit pinout](/doc/Adafruit%20Feather%2032u4%20Bluefruit%20LE%20Pinout.pdf).

## Feedback buttons
Feedback is sent by pressing one of the three feedback buttons; they trigger an interrupt that sets a variable to a certain value that will then be sent to the app bridge (if proto1 is used as a portable version).
```c
  pinMode(positiveButtonPin, INPUT);
  pinMode(neutralButtonPin, INPUT);
  pinMode(negativeButtonPin, INPUT);
  attachInterrupt(1, positive, RISING); //INT1 ASSOCIATO AL PIN 2 -> positiveButtonPin
  attachInterrupt(0, neutral, RISING); //INT0 ASSOCIATO AL PIN 3 -> neutralButtonPin
  attachInterrupt(3, negative, RISING); //INT3 ASSOCIATO AL PIN 1 -> negativeButtonPin
```

## Custom BLE payload
For better compatibility, particularly with Apple devices, the mac address of the dongle was chosen to be included within a special field in the BLE advertisement package.
As it was necessary to enter a unique manufacturer identifier, one of the free values was used: *0xF175* (https://www.bluetooth.com/specifications/assigned-numbers/). This addition was made directly in the setup() function in [proto1.ino](/proto1/proto1.ino).
```c
// set custom payload with manufacturer info
  ble.sendCommandCheckOK(F("AT+GAPSETADVDATA=09-FF-75-F1-EF-41-B7-0D-1F-6C"));
```
