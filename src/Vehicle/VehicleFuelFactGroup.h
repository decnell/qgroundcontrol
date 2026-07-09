/****************************************************************************
 *
 * VehicleFuelFactGroup — FUEL_STATUS (msg id 371) 油箱液位遥测组
 * 数据源: PX4 lide_engine_can 模块 (河南长润液位计 CAN 0x388 → fuel_tank_status)
 *
 ****************************************************************************/

#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class VehicleFuelFactGroup : public FactGroup
{
    Q_OBJECT

public:
    VehicleFuelFactGroup(QObject* parent = nullptr);

    Q_PROPERTY(Fact* percentRemaining READ percentRemaining CONSTANT)
    Q_PROPERTY(Fact* remainingFuel    READ remainingFuel    CONSTANT)
    Q_PROPERTY(Fact* consumedFuel     READ consumedFuel     CONSTANT)
    Q_PROPERTY(Fact* maximumFuel      READ maximumFuel      CONSTANT)
    Q_PROPERTY(Fact* flowRate         READ flowRate         CONSTANT)
    Q_PROPERTY(Fact* temperature      READ temperature      CONSTANT)
    Q_PROPERTY(Fact* tankId           READ tankId           CONSTANT)
    Q_PROPERTY(Fact* fuelType         READ fuelType         CONSTANT)
    Q_PROPERTY(Fact* updateCount      READ updateCount      CONSTANT)

    Fact* percentRemaining () { return &_percentRemainingFact; }
    Fact* remainingFuel    () { return &_remainingFuelFact; }
    Fact* consumedFuel     () { return &_consumedFuelFact; }
    Fact* maximumFuel      () { return &_maximumFuelFact; }
    Fact* flowRate         () { return &_flowRateFact; }
    Fact* temperature      () { return &_temperatureFact; }
    Fact* tankId           () { return &_tankIdFact; }
    Fact* fuelType         () { return &_fuelTypeFact; }
    Fact* updateCount      () { return &_updateCountFact; }

    // Overrides from FactGroup
    virtual void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

    static const char* _percentRemainingFactName;
    static const char* _remainingFuelFactName;
    static const char* _consumedFuelFactName;
    static const char* _maximumFuelFactName;
    static const char* _flowRateFactName;
    static const char* _temperatureFactName;
    static const char* _tankIdFactName;
    static const char* _fuelTypeFactName;
    static const char* _updateCountFactName;

private:
    void _handleFuelStatus(mavlink_message_t& message);

    Fact _percentRemainingFact;
    Fact _remainingFuelFact;
    Fact _consumedFuelFact;
    Fact _maximumFuelFact;
    Fact _flowRateFact;
    Fact _temperatureFact;
    Fact _tankIdFact;
    Fact _fuelTypeFact;
    Fact _updateCountFact;
};
