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

### Window actuator
As it is relegated to the fixed version, it semicompletely demonstrates the operation of a carbon dioxide controller that, when carbon dioxide rises above a certain value, drives a servomotor to open a window and then to close it. Given its demonstrative nature, no further functionality was chosen to be implemented.

### Data reading
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

### Wiring diagram
See *proto1_wiring_diagram.pdf*.

### Feedback buttons
Feedback is sent by pressing one of the three feedback buttons; they trigger an interrupt that sets a variable to a certain value that will then be sent to the app bridge (if proto1 is used as a portable version).
```c
  pinMode(positiveButtonPin, INPUT);
  pinMode(neutralButtonPin, INPUT);
  pinMode(negativeButtonPin, INPUT);
  attachInterrupt(1, positive, RISING); //INT1 ASSOCIATO AL PIN 2 -> positiveButtonPin
  attachInterrupt(0, neutral, RISING); //INT0 ASSOCIATO AL PIN 3 -> neutralButtonPin
  attachInterrupt(3, negative, RISING); //INT3 ASSOCIATO AL PIN 1 -> negativeButtonPin
```

### Custom BLE payload
For better compatibility, particularly with Apple devices, the mac address of the dongle was chosen to be included within a special field in the BLE advertisement package.
As it was necessary to enter a unique manufacturer identifier, one of the free values was used: *0xF175* (https://www.bluetooth.com/specifications/assigned-numbers/). This addition was made directly in the setup() function in *proto1.ino*.
```c
// set custom payload with manufacturer info
  ble.sendCommandCheckOK(F("AT+GAPSETADVDATA=09-FF-75-F1-EF-41-B7-0D-1F-6C"));
```

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

### Data reading
Communication with and reading from sensors is possible through higher-level libraries; communication with the sensors is via I2C protocol. The respective libraries abstract this by giving the developer a much more convenient interface for talking to the various sensors.
The various addresses with which the sensors are associated are given for documentation purposes only:
* **HS3001** 0x44;
* **CCS811** 0x5A;
* **ENS210** 0x43.
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

### Feedback buttons
Feedback is sent by pressing one of the three touch buttons (ESP32 provides pins that function as if they were ordinary touch-screen buttons); they trigger an interrupt that sets a variable to a certain value that will then be sent to the app bridge (if proto1 is used as a portable version).
```c
  // first argument is the PIN used
  // second argument is the isr associated
  // third argument is a value that sets the limit between button pressed/not pressed
  touchAttachInterrupt(T0, positive, 40); // PIN 4 (on right side)
  touchAttachInterrupt(T2, neutral, 40); // PIN 2 (on right side)
  touchAttachInterrupt(T4, negative, 40); // PIN 13 (on left side)
```

### Custom BLE payload
For better compatibility, particularly with Apple devices, the mac address of the dongle was chosen to be included within a special field in the BLE advertisement package.
As it was necessary to enter a unique manufacturer identifier, one of the free values was used: *0xF175* (https://www.bluetooth.com/specifications/assigned-numbers/). This addition was made in the *BleSerial.cpp* library.
```c
    const uint8_t* point = esp_bt_dev_get_address();
    char ManufacturerData[9] = {0x75,0xf1}; // free id 0xF175;
    for (int i = 0; i < 6; i++) ManufacturerData[i+2] = point[i];
    // null-terminate string
    ManufacturerData[8] = 0x00;
    oAdvertisementData.setManufacturerData(ManufacturerData); //to add mac into manufacter data
```

### Wiring diagram
Since everything is already connected on the pcb, please refer to the file [EBV-IoT - ESP32Secure_board_schematic.pdf](/doc/EBV-IoT%20-%20ESP32Secure_board_schematic.pdf).