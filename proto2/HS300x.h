/*

Module: Catena-HS300x.h

Function:
        Definitions for the Catena library for the IDT HS300x sensor family.

Copyright and License:
        See accompanying LICENSE file.

Author:
        Terry Moore, MCCI Corporation   June 2019

*/

#ifndef HS300X_H_
# define HS300X_H_
# pragma once

#include <cstdint>
#include <Wire.h>

namespace HS300x {

/****************************************************************************\
|
|   Version boilerplate
|
\****************************************************************************/

// create a version number for comparison
static constexpr std::uint32_t
makeVersion(
    std::uint8_t major, std::uint8_t minor, std::uint8_t patch, std::uint8_t local = 0
    )
    {
    return ((std::uint32_t)major << 24u) | ((std::uint32_t)minor << 16u) | ((std::uint32_t)patch << 8u) | (std::uint32_t)local;
    }

// extract major number from version
static constexpr std::uint8_t
getMajor(std::uint32_t v)
    {
    return std::uint8_t(v >> 24u);
    }

// extract minor number from version
static constexpr std::uint8_t
getMinor(std::uint32_t v)
    {
    return std::uint8_t(v >> 16u);
    }

// extract patch number from version
static constexpr std::uint8_t
getPatch(std::uint32_t v)
    {
    return std::uint8_t(v >> 8u);
    }

// extract local number from version
static constexpr std::uint8_t
getLocal(std::uint32_t v)
    {
    return std::uint8_t(v);
    }

// version of library, for use by clients in static_asserts
static constexpr std::uint32_t kVersion = makeVersion(0,2,0,0);

/****************************************************************************\
|
|   The sensor class.
|
\****************************************************************************/

class cHS300x
    {
private:
    // control result of isDebug(); use for compiling code in/out.
    static constexpr bool kfDebug = false;

    // the device i2c address. This is fixed by design.
    static constexpr std::int8_t kAddress = 0x44;

    // millisec to delay before reading. This is the datasheet "typical"
    // value of 16.9, rounded up a little.
    static constexpr std::uint32_t kMeasurementDelayMs = 40;

    // how many extra millis to wait before giving up on the data.
    static constexpr std::uint32_t kGetTemperatureTimeoutMs = 100;

public:
    // constructor:
    cHS300x(TwoWire &wire)
            : m_wire(&wire)
            {}

    // neither copyable nor movable
    cHS300x(const cHS300x&) = delete;
    cHS300x& operator=(const cHS300x&) = delete;
    cHS300x(const cHS300x&&) = delete;
    cHS300x& operator=(const cHS300x&&) = delete;

    // convert raw temperature to celsius
    static constexpr float rawTtoCelsius(std::uint16_t tfrac)
        {
        return -40.0f + 165.0f * ((tfrac & 0xFFFC) / float(0xFFFC));
        }

    // convert raw RH to percent.
    static constexpr float rawRHtoPercent(std::uint16_t rhfrac)
        {
        return 100.0f * ((rhfrac & 0xFFFC) / float(0xFFFC));
        }

    // convert Celsius temperature to raw format.
    /*static constexpr std::uint16_t celsiusToRawT(float t)
        {
        t += 40.0f;
        uint16_t var;
        if (t < 0.0f)
            return 0;
        else if (t > 165.0)
            return 0xFFFCu;
        else
            return (std::uint16_t) ((t / 165.0f) * float(0xFFFC));
        }

    // convert RH as percentage to raw format.
    static constexpr std::uint16_t percentRHtoRaw(float rh)
        {
        if (rh > 100.0)
            return 0xFFFCu;
        else if (rh < 0.0)
            return 0;
        else
            return (std::uint16_t) (float(0xFFFC) * (rh / 100.0));
        }
        */
    // raw measurements as a collection.
    struct MeasurementsRaw
        {
        std::uint16_t   TemperatureBits;
        std::uint16_t   HumidityBits;
        void extract(std::uint16_t &a_t, std::uint16_t &a_rh) const
            {
            a_t = this->TemperatureBits;
            a_rh = this->HumidityBits;
            }
        };

    // measurements, as a collection.
    struct Measurements
        {
        float Temperature;
        float Humidity;
        void set(const MeasurementsRaw &mRaw)
            {
            this->Temperature = rawTtoCelsius(mRaw.TemperatureBits);
            this->Humidity = rawRHtoPercent(mRaw.HumidityBits);
            }
        void extract(float &a_t, float &a_rh) const
            {
            a_t = this->Temperature;
            a_rh = this->Humidity;
            }
        };

    // Start operation (return true if successful)
    bool begin();

    // End operation
    void end();

    // get temperature and humidity as normalized 16-bit fractions
    bool getTemperatureHumidityRaw(MeasurementsRaw &mRaw) const;

    // get temperature and humidity as floats in engineering units
    bool getTemperatureHumidity(Measurements &m) const;

    // start a measurement; return the millis to delay before expecting an answer
    std::uint32_t startMeasurement(void) const;

    // get asynch measurement results, if available.
    bool getMeasurementResults(Measurements &m) const;

    // get raw measurement results, if available.
    bool getMeasurementResultsRaw(MeasurementsRaw &mRaw) const;

    // return true if configured for debugging; compile-time constant.
    static constexpr bool isDebug() { return kfDebug; }

    // return the address; for compatibility.
    static constexpr std::int8_t getAddress()
            { return kAddress; }

protected:
    // address the device and read an nBuf-byte response.
    bool readResponse(std::uint8_t *buf, size_t nBuf) const;

private:
    // the I2C bus to use for communication.
    TwoWire *m_wire;
    };

} // namespace McciCatenaHs300x

#endif /* _CATENA_HS300X_H_ */
