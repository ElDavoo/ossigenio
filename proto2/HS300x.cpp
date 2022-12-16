/*

Module: Catena-HS300x.cpp

Function:
        Code for Catena HS300x library

Copyright and License:
        See accompanying LICENSE file.

Author:
        Terry Moore, MCCI Corporation   June 2019

*/

#include "HS300x.h"

using namespace HS300x;

bool cHS300x::begin(void)
    {
    std::uint8_t buf[2];

    this->m_wire->begin();

    /* do a data fetch to see whether we can see the device */
    return this->readResponse(buf, sizeof(buf));
    }

void cHS300x::end(void)
    {
    }

bool cHS300x::getTemperatureHumidity(cHS300x::Measurements &m) const
    {
    MeasurementsRaw mRaw;
    bool fResult;

    fResult = this->getTemperatureHumidityRaw(mRaw);
    if (fResult)
        {
        /* set m from bits in mRaw */
        m.set(mRaw);
        }
    else
        {
        m.Temperature = m.Humidity = NAN;
        }

    return fResult;
    }

bool cHS300x::getTemperatureHumidityRaw(cHS300x::MeasurementsRaw &mRaw) const
    {
    uint32_t msDelay;
    bool fResult;

    fResult = true;
    msDelay = this->startMeasurement();
    if (msDelay == 0)
        {
        fResult = false;
        }

    if (fResult)
        {
        delay(msDelay);

        uint32_t tStart = millis();

        /* loop trying to read data  */
        do  {
            fResult = this->getMeasurementResultsRaw(mRaw);
            } while (! fResult && (millis() - tStart) < this->kGetTemperatureTimeoutMs);
        }

    if (! fResult)
        {
        mRaw.TemperatureBits = mRaw.HumidityBits = 0;
        }

    return fResult;
    }

std::uint32_t cHS300x::startMeasurement(void) const
    {
    std::uint8_t error;

    this->m_wire->beginTransmission(this->getAddress());
    error = this->m_wire->endTransmission();

    if (error != 0)
        {
        if (this->isDebug())
            {
            //Serial.print("startMeasurement: can't select device: error ");
            //Serial.println(unsigned(error));
            }
        return 0;
        }
    else
        {
        return this->kMeasurementDelayMs;
        }
    }

bool cHS300x::getMeasurementResults(cHS300x::Measurements &m) const
    {
    MeasurementsRaw mRaw;
    bool fResult;

    fResult = this->getMeasurementResultsRaw(mRaw);
    if (fResult)
        {
        m.set(mRaw);
        }

    return fResult;
    }

bool cHS300x::getMeasurementResultsRaw(cHS300x::MeasurementsRaw &mRaw) const
    {
    std::uint8_t buf[4];
    bool fResult;

    fResult = this->readResponse(buf, sizeof(buf));
    if (fResult)
        {
        uint8_t status = buf[0] & 0xC0;
        if (status != 0)
            {
            if (this->isDebug())
                {
                //Serial.print("getMeasurementResultsRaw: invalid data status: ");
                //Serial.println(unsigned(status >> 6u));
                }
            fResult = false;
            }
        }

    if (fResult)
        {
        mRaw.TemperatureBits = ((buf[2] << 8) | buf[3]) & 0xFFFCu;
        mRaw.HumidityBits = (buf[0] << 10) | (buf[1] << 2);
        }

    return fResult;
    }

bool cHS300x::readResponse(std::uint8_t *buf, size_t nBuf) const
    {
    bool ok;
    unsigned nResult;
    const std::int8_t addr = this->getAddress();
    uint8_t nReadFrom;

    if (buf == nullptr || nBuf > 32 || addr < 0)
        {
        if (this->isDebug())
            //Serial.println("readResponse: invalid parameter");

        return false;
        }

    nReadFrom = this->m_wire->requestFrom(std::uint8_t(addr), /* bytes */ std::uint8_t(nBuf));

    if (nReadFrom != nBuf)
        {
        if (this->isDebug())
            {
            /*Serial.print("readResponse: nReadFrom(");
            Serial.print(unsigned(nReadFrom));
            Serial.print(") != nBuf(");
            Serial.print(nBuf);
            Serial.println(")");*/
            }
        }
    nResult = this->m_wire->available();

    for (unsigned i = 0; i < nResult; ++i)
        buf[i] = this->m_wire->read();

    if (nResult != nBuf && this->isDebug())
        {
        /*Serial.print("readResponse: nResult(");
        Serial.print(nResult);
        Serial.print(") != nBuf(");
        Serial.print(nBuf);
        Serial.println(")");*/
        }

    return (nResult == nBuf);
    }
