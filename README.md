![ossigenio_landscape copia](https://user-images.githubusercontent.com/7345120/214380344-852bb52a-08c6-4c13-a99f-b96ed6800c03.png)

# Get clean air. Study better.


Ossigenio is a platform for **monitoring air quality** in your surroundings and to check out which study rooms/libraries have and will have the **best air quality**, in order to live a better life!

This is a university project made for the subject "IoT and 3D Intelligent Systems", for Università degli studi di Modena e Reggio Emilia. , year 2022-2023.

## Why?

[Carbon dioxide](https://en.wikipedia.org/wiki/Carbon_dioxide) is a silent performance killer: It is colorless and odorless at low concentration, but [heavily affects](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7420173/) the capacity for students and workers to focus. This has been proved by [several studies](https://commercial.velux.com/blog/learning-environments/why-indoor-air-quality-is-important-and-how-to-improve-it). Performance can be greatly improved but doing something as simple as open the windows, but it can be difficult to understand the optimal opening time to maximize dispersion of CO2 while minimizing the heat loss. Moreover, this process can be automated. Users might also want to monitor the air quality in their personal spaces (for example, their rooms).

## Status of the project

Even though it is only a *prototype*, it is fully functional.

Currently no further development is planned.

Both implementations are based principally on ESP32, which collects some environmental information of the location (temperature, humidity, and carbon dioxide) and sends it to a bridge that is responsible for sending the collected data to the Internet and/or to control an actuator (which could operate the opening of a window to promote air recirculation). 
More detailed documentation can be found below.

# Sub-projects

This project is made of four different components.

## Ossigenio portable sensor (codename proto2)

The [portable version](proto1/) sensor is targeted to single individuals and students who want to have a reliable measurement of carbon dioxide that can work anywhere. It consists of a small dongle that, having collected various data, sends it to a smartphone acting as a bridge, running a special application, between it and the Internet.
![Imgur](https://user-images.githubusercontent.com/4050967/214251875-95307e63-219d-483b-baf8-008ece1dbdb0.jpg)

## Ossigenio fixed sensor (codename proto1)
The [fixed version](proto2/) is targeted to universities and managers who want to let their places show up in the [companion app](). It consists solely and exclusively of the ESP32, which, once data is collected, controls the **opening/closing of windows**, via a servomotor, to allow **automatic air recirculation** and bring air quality levels back to an acceptable level.  
  
![Imgur](https://user-images.githubusercontent.com/4050967/214252089-7a0dd76d-0b9c-47e1-b565-18e969a560d7.jpg)  
  
## Ossigenio (companion app)
![app-landscape](https://user-images.githubusercontent.com/7345120/214387507-17b703d5-7514-4a2e-ba6b-eb31e0110eb1.jpg)

The multi-platform [application](flutter_app/) for mobile devices is the primary interface for a [portable sensor](#ossigenio-portable-sensor-codename-proto2), and it also features an **interactive map** to see the current *and future* air quality level on nearby study places. This allows users that do not own a sensor to decide which are the best places.  

## Backend

The [server](flask/) part of the application stores the places and the data received by the sensors, thanks to which it can estimate the air quality in a place. Thanks to AI, it can also **make predictions** about the future situation.

### Telegram interface

The Telegram interface is targeted to place managers that can't use a [fixed version](#ossigenio-fixed-sensor-codename-proto1). It allows to **receive notifications** when the air quality level drops below a configurable level, so that appropriate actions can be taken.

### Privacy
For every place, we store its name and its GPS coordinates.  
For every user, we store its username, its email address and its password.  
The password is **hashed and salted**. Furthermore, anyone trying to login must hash the password theirselves before sending it to server. This ensures the plaintext password is never compromised.  

Sensors periodically send information about the air quality to the server. This includes the ID of the place the user is in. The app sends the GPS coordinates to the server, which returns a list of nearby places. These coordinates are **not stored**.  

The app uses **encrypted storage** to further enhance the security of the user's account info.
