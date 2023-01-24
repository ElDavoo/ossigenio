# prototypes.md
## proto1
First prototype developed and based upon Adafruit Feather 32u4 board; chosen because of low cost and compatibility with the Arduino development environment.
Discarded later because of low performance and unreliability of sensors, particularly the carbon dioxide sensor. It is currently relegated for the fixed version.

![Imgur](https://user-images.githubusercontent.com/4050967/214252089-7a0dd76d-0b9c-47e1-b565-18e969a560d7.jpg)

### Firmware development
Due to Arduino compatibility, this environment was used for its development. Software requirements are available on *Requirements.md*.
The BLE part is based on the Nordic nrf51 chip, consequently, custom libraries from Adafruit were used which based, in turn, on the libraries of the RF chip. They provide serial-type communication similar in operation to the common UART.
A special communication protocol, **Protobuf**, was implemented to ensure reliable communication between the prototype and the bridge (smartphone); see *SerialProtocol.md* for details.

### Sensors chosen
For environmental data sampling, we chose these sensors:
* DHT11 (temperature and humidity);
* MQ135 (carbon dioxide).
In particular MQ135 did not seem to be very reliable and was one of the main reasons in which alternatives were sought.


## proto2
Developed using ESP32-D board on devkit 36; chosen because of excellent cost-performance ratio and compatibility with the Arduino development environment.

![Imgur](https://user-images.githubusercontent.com/4050967/214251875-95307e63-219d-483b-baf8-008ece1dbdb0.jpg)

### Firmware development
The Arduino core was used to write the firmware so that much of the code that had been written for the previous model could be reused, i.e., proto1, which was then relegated to being a prototype for the fixed version. Software requirements are available on *Requirements.md*.
For communication via Bluetooth LE, the choice fell on the implementation of a virtual serial that emulates the operation of the traditional UART; it is based on an available open-source library.
Again **Protobuf** was used as the communication protocol and please see *SerialProtocol.md* for details.

### Sensors chosen
For environmental data sampling, we chose to rely on some of the sensors available on the EBV sensor board, which were found to be much more accurate than those used on the proto1 model:
* HS3001 (temperature and humidity);
* CCS811 (carbon dioxide);
* ENS210 (temperature of the above sensor).
Other sensors did not seem useful for our purpose.
Some software libraries used were sourced from the Internet as open-source if not already available out-of-the-box with the Arduino ide. See *Requirements.md* for further details. 