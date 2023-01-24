# proto2.md
Developed using ESP32-D board on devkit 36; chosen because of excellent cost-performance ratio.

### Firmware development
The Arduino core was used to write the firmware so that much of the code that had been written for the previous model could be reused, i.e., proto1, which was then relegated to being a prototype for the fixed version.
For communication via Bluetooth LE, the choice fell on the implementation of a virtual serial that emulates the operation of the traditional UART; it is based on an available open-source library. 

### Sensors chosen.
For environmental data sampling, we chose to rely on some of the sensors available on the EBV sensor board, which were found to be much more accurate than those used on the proto1 model:
* HS3001 (temperature and humidity);
* CCS811 (carbon dioxide);
* ENS210 (temperature of the above sensor).
Other sensors did not seem useful for our purpose.