# Technical documentation of prototype proto2
Developed using ESP32-D board on devkit 36; chosen because of excellent cost-performance ratio and compatibility with the Arduino development environment.

![Imgur](https://user-images.githubusercontent.com/4050967/214251875-95307e63-219d-483b-baf8-008ece1dbdb0.jpg)

## Firmware development
The Arduino core was used to write the firmware so that much of the code that had been written for the previous model could be reused, i.e., proto1, which was then relegated to being a prototype for the fixed version. Software requirements are available on [Requirements.md](/doc/Requirements.md). Development directly on the Espressif core would have been possible, allowing much more efficient use of the hardware, but it would have required a rewrite of the code from scratch, and it was therefore chosen to shelve that solution.
For communication via Bluetooth LE, the choice fell on the implementation of a virtual serial that emulates the operation of the traditional UART; it is based on an available open-source library.
Again, a special serial communication protocol was used as the communication protocol and please see [SerialProtocol.md](/doc/SerialProtocol.md) for details.

## Sensors chosen
For environmental data sampling, we chose to rely on some of the sensors available on the EBV sensor board, which were found to be much more accurate than those used on the proto1 model:
* [HS3001](/doc/HS300x-Datasheet.pdf) (temperature and humidity);
* [CCS811](/doc/CCS811_Datasheet.pdf) (carbon dioxide);
* [ENS210](/doc/ENS210_Datasheet.pdf) (temperature of the above sensor).
Other sensors did not seem useful for our purpose.
Some software libraries used were sourced from the Internet as open-source if not already available out-of-the-box with the Arduino ide. See [Requirements.md](/doc/Requirements.md) for further details. 

## Data reading
Communication with and reading from sensors is possible through higher-level libraries; communication with the sensors is via I2C protocol. The respective libraries abstract this by giving the developer a much more convenient interface for talking to the various sensors.
The various addresses with which the sensors are associated are given for documentation purposes only:
* HS3001 *0x44*;
* CCS811 *0x5A*;
* ENS210 *0x43*.
```c
// used millis() function
 if (currentMillis - lastExecutedMillis >= campTime) { // with campTime normally equal to 10 seconds
    lastExecutedMillis = currentMillis; // save the last executed time

    // temperature and humidity section
    if (gHs300x.getTemperatureHumidity(m)){
      m.extract(temperature, humidity); // read temperature and humidity values
    }

    // co2 section (read also co2 sensor temperature for reliability purpose)
    if (mySensor.dataAvailable()) {
      mySensor.readAlgorithmResults();
      co2 = (float) mySensor.getCO2(); // read co2 value
      ens210.measure(&t_data, &t_status, &h_data, &h_status ); //see after comment
      raw = (int) ens210.toCelsius(t_data,10)/10.0; //temperature of co2 sensor
    }
    feed = false; //re-enabling feedback disabled into isr
  }
```

## Feedback buttons
Feedback is sent by pressing one of the three touch buttons (ESP32 provides pins that function as if they were ordinary touch-screen buttons); they trigger an interrupt that sets a variable to a certain value that will then be sent to the app bridge (if proto1 is used as a portable version).
```c
  // first argument is the PIN used
  // second argument is the isr associated
  // third argument is a value that sets the limit between button pressed/not pressed
  touchAttachInterrupt(T0, positive, 40); // PIN 4 (on right side)
  touchAttachInterrupt(T2, neutral, 40); // PIN 2 (on right side)
  touchAttachInterrupt(T4, negative, 40); // PIN 13 (on left side)
```

## Custom BLE payload
For better compatibility, particularly with Apple devices, the mac address of the dongle was chosen to be included within a special field in the BLE advertisement package.
As it was necessary to enter a unique manufacturer identifier, one of the free values was used: *0xF175* (https://www.bluetooth.com/specifications/assigned-numbers/). This addition was made in the [BleSerial.cpp](/proto2/BleSerial.cpp) library.
```c
    const uint8_t* point = esp_bt_dev_get_address();
    char ManufacturerData[9] = {0x75,0xf1}; // free id 0xF175;
    for (int i = 0; i < 6; i++) ManufacturerData[i+2] = point[i];
    // null-terminate string
    ManufacturerData[8] = 0x00;
    oAdvertisementData.setManufacturerData(ManufacturerData); //to add mac into manufacter data
```

## Power saving
In order to optimize power consumption, the choice was made to bring the CPU to the lowest allowable frequency (from 240MHz to 80MHz - lower values disable Wi-Fi/BT) and the TX power of the BLE was lowered (from the default value of 3dBm or 1.41mW to -12dBm or 0.25mW), managing to keep the current draw of the single board to minus 100mA. 
It was not possible to take advantage of the various sleep-modes available because their use involves disabling the RF circuitry (the most power-hungry part of the entire prototype) or, e.g., disabling one of the two available cores.
Estimated sensor consumptions:
* CCS811: 15mA with mode 1 (measurement every second) - high power consumption due to internal resistance.
* ENS210: 7.1 microA
* HS3001: 24.4 microA with 14-bit resolution.

## Wiring diagram
Since everything is already connected on the pcb, please refer to the file [EBV-IoT - ESP32Secure_board_schematic.pdf](/doc/EBV-IoT%20-%20ESP32Secure_board_schematic.pdf).
See also [ESP32](/doc/esp32_datasheet_en.pdf).