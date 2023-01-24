# Ossigenio
A monitor for air quality, made for IoT and 3D Intelligent Systems @ UniMORE A.A. 2022-2023.
Both implementations are based principally on ESP32, which collects some environmental information of the location (temperature, humidity, and carbon dioxide) and sends it to a bridge that is responsible for sending the collected data to the Internet and/or to control an actuator (which could operate the opening of a window to promote air recirculation). 

### Portable version
The portable version consists of a small dongle that, having collected various data, sends it to a smartphone acting as a bridge, running a special application, between it and the Internet.
The app, written primarily for Android but with a ready-made iOS porting, also allows the user to see the previous situation thanks to information collected from other users.
![Imgur](https://user-images.githubusercontent.com/4050967/214251875-95307e63-219d-483b-baf8-008ece1dbdb0.jpg)

### Fixed version
The fixed version consists solely and exclusively of the ESP32, which, once data is collected, controls the opening/closing of windows, via a servomotor, to allow air recirculation and bring air quality levels below an acceptable level.
![Imgur](https://user-images.githubusercontent.com/4050967/214252089-7a0dd76d-0b9c-47e1-b565-18e969a560d7.jpg)
