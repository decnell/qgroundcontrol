/****************************************************************************
 *
 * VehicleFuelFactGroup — FUEL_STATUS (msg id 371) 油箱液位遥测组
 *
 ****************************************************************************/

#include "VehicleFuelFactGroup.h"
#include "Vehicle.h"

const char* VehicleFuelFactGroup::_percentRemainingFactName = "percentRemaining";
const char* VehicleFuelFactGroup::_remainingFuelFactName    = "remainingFuel";
const char* VehicleFuelFactGroup::_consumedFuelFactName     = "consumedFuel";
const char* VehicleFuelFactGroup::_maximumFuelFactName      = "maximumFuel";
const char* VehicleFuelFactGroup::_flowRateFactName         = "flowRate";
const char* VehicleFuelFactGroup::_temperatureFactName      = "temperature";
const char* VehicleFuelFactGroup::_tankIdFactName           = "tankId";
const char* VehicleFuelFactGroup::_fuelTypeFactName         = "fuelType";
const char* VehicleFuelFactGroup::_updateCountFactName      = "updateCount";

VehicleFuelFactGroup::VehicleFuelFactGroup(QObject* parent)
    : FactGroup(1000, ":/json/Vehicle/FuelFact.json", parent)
    , _percentRemainingFact (0, _percentRemainingFactName, FactMetaData::valueTypeDouble)
    , _remainingFuelFact    (0, _remainingFuelFactName,    FactMetaData::valueTypeFloat)
    , _consumedFuelFact     (0, _consumedFuelFactName,     FactMetaData::valueTypeFloat)
    , _maximumFuelFact      (0, _maximumFuelFactName,      FactMetaData::valueTypeFloat)
    , _flowRateFact         (0, _flowRateFactName,         FactMetaData::valueTypeFloat)
    , _temperatureFact      (0, _temperatureFactName,      FactMetaData::valueTypeFloat)
    , _tankIdFact           (0, _tankIdFactName,           FactMetaData::valueTypeUint8)
    , _fuelTypeFact         (0, _fuelTypeFactName,         FactMetaData::valueTypeUint32)
    , _updateCountFact      (0, _updateCountFactName,      FactMetaData::valueTypeUint32)
{
    _addFact(&_percentRemainingFact, _percentRemainingFactName);
    _addFact(&_remainingFuelFact,    _remainingFuelFactName);
    _addFact(&_consumedFuelFact,     _consumedFuelFactName);
    _addFact(&_maximumFuelFact,      _maximumFuelFactName);
    _addFact(&_flowRateFact,         _flowRateFactName);
    _addFact(&_temperatureFact,      _temperatureFactName);
    _addFact(&_tankIdFact,           _tankIdFactName);
    _addFact(&_fuelTypeFact,         _fuelTypeFactName);
    _addFact(&_updateCountFact,      _updateCountFactName);

    _percentRemainingFact.setRawValue(qQNaN());
    _remainingFuelFact.setRawValue(qQNaN());
    _consumedFuelFact.setRawValue(qQNaN());
    _maximumFuelFact.setRawValue(qQNaN());
    _flowRateFact.setRawValue(qQNaN());
    _temperatureFact.setRawValue(qQNaN());
}

void VehicleFuelFactGroup::handleMessage(Vehicle* /* vehicle */, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_FUEL_STATUS:
        _handleFuelStatus(message);
        break;
    default:
        break;
    }
}

void VehicleFuelFactGroup::_handleFuelStatus(mavlink_message_t& message)
{
    mavlink_fuel_status_t fuel;
    mavlink_msg_fuel_status_decode(&message, &fuel);

    percentRemaining()->setRawValue((fuel.percent_remaining == 255) ? qQNaN() : (double)fuel.percent_remaining);
    remainingFuel()->setRawValue(fuel.remaining_fuel);
    consumedFuel()->setRawValue(fuel.consumed_fuel);
    maximumFuel()->setRawValue(fuel.maximum_fuel);
    flowRate()->setRawValue(fuel.flow_rate);
    temperature()->setRawValue(fuel.temperature);
    tankId()->setRawValue(fuel.id);
    fuelType()->setRawValue(fuel.fuel_type);

    // 心跳计数: 每收到一帧 FUEL_STATUS 自增
    updateCount()->setRawValue(updateCount()->rawValue().toUInt() + 1);
    _setTelemetryAvailable(true);
}
