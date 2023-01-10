/*
Libreria esterna BLESerial.cpp, implementa la comunicazione seriale su bluetooth low energy
*/
#include "BleSerial.h"
using namespace std;

bool BleSerial::connected()
{
	return Server->getConnectedCount() > 0;
}

void BleSerial::onConnect(BLEServer *pServer)
{
	bleConnected = true;
	if(enableLed) digitalWrite(ledPin, LOW); 
	/* 
	Turning on connection led on connect. Why i'm using low instead of HIGH? Because on this devkit, led are connected to +3.3V instead of GND.
	Check datasheet for further details
	*/
}

void BleSerial::onDisconnect(BLEServer *pServer)
{
	bleConnected = false;
	if(enableLed) digitalWrite(ledPin, HIGH); //turning off connection led on disconnect; see comments before
	Server->startAdvertising();
}

int BleSerial::read()
{
	uint8_t result = this->receiveBuffer.pop();
	if (result == (uint8_t)'\n')
	{
		this->numAvailableLines--;
	}
	return result;
}

size_t BleSerial::readBytes(uint8_t *buffer, size_t bufferSize)
{
	int i = 0;
	while (i < bufferSize && available())
	{
		buffer[i] = this->receiveBuffer.pop();
		i++;
	}
	return i;
}

int BleSerial::peek()
{
	if (this->receiveBuffer.getLength() == 0)
		return -1;
	return this->receiveBuffer.get(0);
}

int BleSerial::available()
{
	return this->receiveBuffer.getLength();
}

size_t BleSerial::print(const char *str)
{
	if (Server->getConnectedCount() <= 0)
	{
		return 0;
	}

	size_t written = 0;
	for (size_t i = 0; str[i] != '\0'; i++)
	{
		written += this->write(str[i]);
	}
	flush();
	return written;
}

size_t BleSerial::write(const uint8_t *buffer, size_t bufferSize)
{
	if (Server->getConnectedCount() <= 0)
	{
		return 0;
	}

	if (maxTransferSize < MIN_MTU)
	{
		int oldTransferSize = maxTransferSize;
		peerMTU = Server->getPeerMTU(Server->getConnId()) - 5;
		maxTransferSize = peerMTU > BLE_BUFFER_SIZE ? BLE_BUFFER_SIZE : peerMTU;

		if (maxTransferSize != oldTransferSize)
		{
			log_e("Max BLE transfer size set to %u", maxTransferSize);
		}
	}

	if (maxTransferSize < MIN_MTU){
		return 0;
	}

	
	size_t written = 0;
	for (int i = 0; i < bufferSize; i++)
	{
		written += this->write(buffer[i]);
	}
	flush();
	return written;
}

size_t BleSerial::write(uint8_t byte)
{
	if (Server->getConnectedCount() <= 0)
	{
		return 0;
	}
	this->transmitBuffer[this->transmitBufferLength] = byte;
	this->transmitBufferLength++;
	if (this->transmitBufferLength == sizeof(this->transmitBuffer))
	{
		flush();
	}
	return 1;
}

void BleSerial::flush()
{
	if (this->transmitBufferLength > 0)
	{
		TxCharacteristic->setValue(this->transmitBuffer, this->transmitBufferLength);
		this->transmitBufferLength = 0;
	}
	this->lastFlushTime = millis();
	TxCharacteristic->notify(true);
}

void BleSerial::begin(const char *name,bool enable_led, int led_pin)
{
	enableLed = enable_led;
	ledPin = led_pin;

	if(enableLed){
		pinMode(ledPin,OUTPUT);
		digitalWrite(ledPin, HIGH); //turning off led at library startup (otherwise it automatically turning on at startup)
	}
	//characteristic property is what the other device does.

	ConnectedDeviceCount = 0;
	BLEDevice::init(name);
	BLEDevice::setPower(ESP_PWR_LVL_N12); // setting ble power to -12dBm; default is ESP_PWR_LVL_P3 (+3 dBm)
	BLEDevice::setPower(ESP_PWR_LVL_N12,ESP_BLE_PWR_TYPE_ADV);
	BLEDevice::setPower(ESP_PWR_LVL_N12,ESP_BLE_PWR_TYPE_SCAN);

	Server = BLEDevice::createServer();
	Server->setCallbacks(this);

	SetupSerialService();

	const uint8_t* point = esp_bt_dev_get_address();
	char ManufacturerData[9] = {0x75,0xf1}; //0xF175; id produttore preso a caso tra quelli liberi
	for (int i = 0; i < 6; i++) ManufacturerData[i+2] = point[i];
	// null-terminate string
	ManufacturerData[8] = 0x00;
	oAdvertisementData.setManufacturerData(ManufacturerData); //to add mac into manufacter data; thanks Apple! -.-"

	pAdvertising = BLEDevice::getAdvertising();
	pAdvertising->setAdvertisementData(oAdvertisementData);
	// it doesn't fit anyway
	// pAdvertising->addServiceUUID(BLE_SERIAL_SERVICE_UUID);
	pAdvertising->setScanResponse(true);
	pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connections issue
	pAdvertising->setMinPreferred(0x12);
	pAdvertising->start();

	//pSecurity = new BLESecurity();

	//Set static pin
	//uint32_t passkey = 123456;
	//esp_ble_gap_set_security_param(ESP_BLE_SM_SET_STATIC_PASSKEY, &passkey, sizeof(uint32_t));
	//pSecurity->setCapability(ESP_IO_CAP_OUT);
}

void BleSerial::end()
{
	BLEDevice::deinit();
}

void BleSerial::onWrite(BLECharacteristic *pCharacteristic)
{
	if (pCharacteristic->getUUID().toString() == BLE_RX_UUID)
	{
		std::string value = pCharacteristic->getValue();

		if (value.length() > 0)
		{
			for (int i = 0; i < value.length(); i++)
				receiveBuffer.add(value[i]);
		}
	}
}

void BleSerial::SetupSerialService()
{
	SerialService = Server->createService(BLE_SERIAL_SERVICE_UUID);

	RxCharacteristic = SerialService->createCharacteristic(
		BLE_RX_UUID, BLECharacteristic::PROPERTY_WRITE);

	TxCharacteristic = SerialService->createCharacteristic(
		BLE_TX_UUID, BLECharacteristic::PROPERTY_NOTIFY);

	TxCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ); //SET UP LIKE THIS INSTEAD OF ESP_GATT_PERM_READ_ENCRYPTED TO avoiding pairing
	RxCharacteristic->setAccessPermissions(ESP_GATT_PERM_WRITE); //SET UP LIKE THIS INSTEAD OF ESP_GATT_PERM_WRITE_ENCRYPTED TO avoiding pairing

	TxCharacteristic->addDescriptor(new BLE2902());
	RxCharacteristic->addDescriptor(new BLE2902());

	TxCharacteristic->setReadProperty(true);
	RxCharacteristic->setWriteProperty(true);
	RxCharacteristic->setCallbacks(this);
	SerialService->start();
}

BleSerial::BleSerial()
{
}
