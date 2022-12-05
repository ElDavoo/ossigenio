## The PDP (Protobuf Dei Poveri) serial protocol

The serial protocol aims to have these characteristics:
- Reduced message size
- Correctness of message (length and CRC check)
- Message version system

### Limitations
A single payload is limited to 255 bytes (length FF).  
Program has to hardcode which data are being sent and where.  
Only 16 message types can exist, and they must be hardcoded in the program.  

### The first byte

The first byte is AX, where X is the message type (from 0 to F).  
For example A0,A1...AF.  

### The second byte

The second byte is the length of the payload (so from the first byte of the payload to the last). The CRC is excluded.  

### CRC8

CRC8 (which?) is used as checksum, **including the header and the length.**

In case of a string, the length of the string must be prefixed.

```bytefield
(def svg-attrs {:style "background-color:white"})
(def boxes-per-row 2)
(def box-width 70)
(def left-margin 1)
(draw-box "aVersion")
(draw-box "Len")
(draw-gap "payload")
(draw-box "CRC8")
(draw-bottom)
```
![image](https://user-images.githubusercontent.com/4050967/204576738-7696bc1a-cf01-4922-8fbb-d043fcafbe89.jpg)

### Messages explanation
#### msg0 packet

1. Start string (AA)
2. Length (number of fields = 8)
3. Message type (0)
4. Payload
	1. temperature
	2. humidity
	3. raw_data
5. End string (FFFF)
6. CRC8 value

#### msg1 packet

1. Start string (AA)
2. Length (number of fields = 8)
3. Message type (1)
4. Payload
	1. temperature
	2. humidity
	3. co2
5. End string (FFFF)
6. CRC8 value

#### msg3 packet

1. Start string (AA)
2. Length (number of fields = 8)
3. Message type (3)
4. Payload
	1. model
	2. version
	3. battery
5. End string (FFFF)
6. CRC8 value

#### msg4 packet

1. Start string (AA)
2. Length (number of fields = 9)
3. Message type (4)
4. Payload
	1. temperature
	2. humidity
	3. co2
	4. feedback value (positive=1, neutral=2, negative=3);
5. End string (FFFF)
6. CRC8 value

### Data types

Int = 16 bits

### Message types
|Index   |Description   |Data|Notes|
|---|---|----|----|
|0|Standard debug message|Temp(int), hum(int),raw(int)|
|1|co2 only message|Temp(int), hum(int),co2(int)|
|2|extended data message|Temp (int), hum(int), co2(int)...|TODO
|3|Startup information|Model(int),Version(int),battery(int)|battery can be 0 if sensor not present
|4|feedback message|Temp(int), hum(int),co2(int), feedback(uint8_t)| Feedback message
|F|Request for message 0|AA1F
|E|Request for message 1|AA1E
|D|Request for message 2|AA1D
|C|Request for message 3|AA1C
|B|Request for message 4|AA1B

#### Automatic message sending
The sensor should send a 
1 
message every 
30
seconds (indeed, every 30 loop cycles. Millis() and micros() seems broken so we are going to use this workaround; perdonaci Dio dell'informatica).
