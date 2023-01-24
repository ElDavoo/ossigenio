## serial protocol

The serial protocol aims to have these characteristics:
- Reduced message size
- Correctness of message (length and CRC check)
- Message version system

### Limitations
A single payload is limited to 255 bytes (length FF).  
Program has to hardcode which data are being sent and where.  
Only 16 message types can exist, and they must be hardcoded in the program.  

![Protobuf generic packet](https://user-images.githubusercontent.com/4050967/214259717-1bf1f5ae-9090-495e-82ca-f4c8f70db632.png)

### The first byte

The first byte is a simply start header: 0xAA.  

### The second byte

The second byte is the length of the payload (so from the first byte of the payload to the last). The CRC is excluded.  

### The third byte

The third byte is XY, where X is the length of the payload, from the first byte of the payload to the last, without CRC field; Y is the message type (from 0 to F).  
Examples of this byte can be 0x80, 0x81, ...,0x8F.

### CRC8

CRC8 selfwritten library is used as checksum, **including the header and the length.**
```c
// checksum calculator
uint8_t checksumCalculator(uint8_t *data, uint8_t length){
   uint8_t curr_crc = 0x0000;
   uint8_t sum1 = (uint8_t) curr_crc;
   uint8_t sum2 = (uint8_t) (curr_crc >> 8);
   int index;
   for(index = 0; index < length; index = index+1)
   {
      sum1 = (sum1 + data[index]) % 255;
      sum2 = (sum2 + sum1) % 255;
   }
   return (sum2 << 8) | sum1;
}
```

### Messages explanation
#### msg0 packet

1. Start string (AA)
2. Length (number of fields = 8)
3. Message type (0)
4. Payload
	1. temperature
	2. humidity
	3. raw_data high byte
	4. raw_data low byte
5. End string (FF)
6. CRC8 value

```c
//Answer to AA1FFF MESSAGE
void getMsg0(int temp, int humidity, int raw_data){
    uint8_t buffer[8];

    buffer[0] = 0xAA;
    buffer[1] = 0x80;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(raw_data);
    buffer[5] = lowByte(raw_data);
    buffer[6] = 0xFF;

    uint8_t message[4];

    message[0] = (uint8_t) 0xAA80;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) raw_data;

    uint8_t crc = checksumCalculator(message,4);
    buffer[7] = crc;
    ble.write(buffer,8);
}
```

#### msg1 packet

1. Start string (AA)
2. Length (number of fields = 8)
3. Message type (1)
4. Payload
	1. temperature
	2. humidity
	3. co2 high byte
	4. co2 low byte
5. End string (FF)
6. CRC8 value

```c
//Answer to AA1EFF MESSAGE
void getMsg1(int temp, int humidity, int co2) {

    uint8_t buffer[8];
    uint8_t message[4];

    message[0] = (uint8_t) 0xAA81;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) co2;

    buffer[0] = 0xAA;
    buffer[1] = 0x81;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(co2);
    buffer[5] = lowByte(co2);
    buffer[6] = 0xFF;
    uint8_t crc = checksumCalculator(message,4);
    buffer[7] = crc;
    ble.write(buffer,8);
}
```

#### msg3 packet

1. Start string (AA)
2. Length (number of fields = 8)
3. Message type (3)
4. Payload
	1. model
	2. version
	3. serial number first byte
	4. serial number second byte
	5. serial number third byte
	6. serial number fourth byte
	7. battery
5. End string (FF)
6. CRC8 value

```c
//Answer to AA1CFF MESSAGE
void getMsg3(){
    uint8_t battery = 100;
    uint8_t buffer[11];
    buffer[0] = 0xAA;
    buffer[1] = 0x83;
    buffer[2] = (uint8_t) MODEL;
    buffer[3] = (uint8_t) VERSION;
    buffer[4] = (uint8_t) ((serialNumber) >> 24); //primo byte
    buffer[5] = (uint8_t) (((serialNumber) & 0x00ff0000) >> 16); //secondo
    buffer[6] = (uint8_t) (((serialNumber) & 0x0000ff00) >> 8); //terzo
    buffer[7] = (uint8_t) (((serialNumber) & 0x000000ff)); //quarto
    buffer[8] = battery;
    buffer[9] = 0xFF;

    uint8_t message[9];

    message[0] = (uint8_t) 0xAA;
    message[1] = (uint8_t) 0x83;
    message[2] = (uint8_t) MODEL;
    message[3] = (uint8_t) VERSION;
    message[4] = (uint8_t) ((serialNumber) >> 24); //primo byte
    message[5] = (uint8_t) (((serialNumber) & 0x00ff0000) >> 16); //secondo
    message[6] = (uint8_t) (((serialNumber) & 0x0000ff00) >> 8); //terzo
    message[7] = (uint8_t) (((serialNumber) & 0x000000ff)); //quarto
    message[8] = (uint8_t) battery;

    uint8_t crc = checksumCalculator(message,9); 
    buffer[10] = crc;
    ble.write(buffer,11); 
}
```

#### msg4 packet

1. Start string (AA)
2. Length (number of fields = 9)
3. Message type (4)
4. Payload
	1. temperature
	2. humidity
	3. co2 high byte
	4. co2 low byte
	5. feedback value (positive=1, neutral=2, negative=3);
5. End string (FF)
6. CRC8 value

```c
//Answer to AA1BFF MESSAGE
void getMsg4(int temp, int humidity, int co2, uint8_t feedback) {
    uint8_t buffer[9];

    buffer[0] = 0xAA;
    buffer[1] = 0x84;
    buffer[2] = (uint8_t) temp;
    buffer[3] = (uint8_t) humidity;
    buffer[4] = highByte(co2);
    buffer[5] = lowByte(co2);
    buffer[6] = feedback;
    buffer[7] = 0xFF;

    uint8_t message[5];

    message[0] = (uint8_t) 0xAA81;
    message[1] = (uint8_t) temp;
    message[2] = (uint8_t) humidity;
    message[3] = (uint8_t) co2;
    message[4] = (uint8_t) feedback;

    uint8_t crc = checksumCalculator(message,5);
    buffer[8] = crc;
    ble.write(buffer,9);
}
```

### Data types

uint8_t = 8 bits

### Message types
|Index   |Description   |Data|Notes|
|---|---|----|----|
|0|Raw info message|Temp(int), hum(int),raw(int)|*It sends raw data for co2 sensor calibration (proto1: raw info from co2 sensor; proto2: co2 sensor temp)*
|1|co2 only message|Temp(int), hum(int),co2(int)|
|2|extended data message|Temp (int), hum(int), co2(int)...|*Reserved for future use*
|3|Startup information|Model(int),Version(int),battery(int)|battery can be 0 if sensor not present
|4|feedback message|Temp(int), hum(int),co2(int), feedback(uint8_t)| Feedback message and debug mode toggle
|F|Request for message 0|AA1F and empty payload
|E|Request for message 1|AA1E and empty payload
|D|Request for message 2|AA1D and empty payload
|C|Request for message 3|AA1C and empty payload
|B|Request for message 4|AA1B and empty payload

#### Automatic message sending
The sensor should send a 1-type message every 10 seconds.

#### Debug mode (currently only on proto2 model)
By sending request B, proto2 enters debug mode: sending a first message 4 with feedback set to 123 and changing the frequency of sending messages 1 from 10 seconds to 1 second.
