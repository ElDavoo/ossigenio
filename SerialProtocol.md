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
(draw-box "0xff - end payload mark")
(draw-box "CRC8")
(draw-bottom)
```
![image](https://user-images.githubusercontent.com/7345120/204289800-326c3dc8-2627-4496-a3aa-bab6e0fb735e.png)

### Data types

Int = 16 bits

### Message types
|Index   |Description   |Data|Notes|
|---|---|----|----|
|0|Standard debug message|Temp(int), hum(int),raw(int)|
|1|co2 only message|Temp(int), hum(int),co2(int)|
|2|extended data message|Temp (int), hum(int), co2(int)...|TODO
|3|Startup information|Model(int),Version(int),battery(int)|battery can be 0 if sensor not present
|F|Request for message 0
|E|Request for message 1
|D|Request for message 2
|C|Request for message 3

#### Automatic message sending
The sensor should send a 
1 
message every 
30
seconds.
