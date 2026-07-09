/****************************************************************************
 *
 * EngineIndicator.qml — 发动机状态 + 油量 工具栏指示器 (砺德 B2GH120D)
 *
 * 顶栏显示: 发动机图标(按健康状态着色) + 转速 + 油量%
 * 点击弹出: 完整发动机仪表页 (转速/油门/缸温/排温/油耗/油量/健康状态)
 *
 * 数据源: EFI_STATUS (efi 组) + FUEL_STATUS (fuel 组)
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

Item {
    id:             _root
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          engineRow.width

    // 常显: 连上飞控即显示。三态: 未接入(灰) / 链路丢失(红) / 正常(按发动机状态着色)
    property bool showIndicator: _activeVehicle !== null

    property var _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var _efi:              _activeVehicle ? _activeVehicle.efi : null
    property var _fuel:             _activeVehicle ? _activeVehicle.fuel : null

    // ---- 链路新鲜度: FactGroup.updateCount 每帧自增, 超时判丢失 ----
    property real _nowMs:      Date.now()
    property real _lastEfiMs:  0
    property real _lastFuelMs: 0

    readonly property int _efiTimeoutMs:  5000   // EFI_STATUS 2Hz → 5s 无帧判丢失
    readonly property int _fuelTimeoutMs: 15000  // FUEL_STATUS 1Hz(液位计3s周期) → 15s

    property bool _efiEverSeen:  _efi  ? _efi.telemetryAvailable  : false
    property bool _fuelEverSeen: _fuel ? _fuel.telemetryAvailable : false
    property bool _efiFresh:     _efiEverSeen  && (_nowMs - _lastEfiMs)  < _efiTimeoutMs
    property bool _fuelFresh:    _fuelEverSeen && (_nowMs - _lastFuelMs) < _fuelTimeoutMs
    property bool _efiLost:      _efiEverSeen  && !_efiFresh
    property bool _fuelLost:     _fuelEverSeen && !_fuelFresh

    property bool _engineAvailable: _efiFresh  && !isNaN(_efi.rpm.rawValue)
    property bool _fuelAvailable:   _fuelFresh && !isNaN(_fuel.percentRemaining.rawValue)

    Timer {
        interval: 1000
        running:  _root.visible
        repeat:   true
        onTriggered: _root._nowMs = Date.now()
    }

    Connections {
        target: _efi ? _efi.updateCount : null
        function onRawValueChanged(value) { _root._lastEfiMs = Date.now(); _root._nowMs = Date.now() }
    }

    Connections {
        target: _fuel ? _fuel.updateCount : null
        function onRawValueChanged(value) { _root._lastFuelMs = Date.now() }
    }

    // EFI_STATUS.health ← PX4 internal_combustion_engine_status.state
    // 0=STOPPED 1=STARTING 2=RUNNING 3=FAULT
    property int  _engineState:     (_efiFresh && !isNaN(_efi.health.rawValue)) ? _efi.health.rawValue : -1

    function engineStateText() {
        if (!_efiEverSeen) {
            return qsTr("未接入")
        }
        if (_efiLost) {
            return qsTr("ECU 链路丢失")
        }
        switch (_engineState) {
        case 0:  return qsTr("已停机")
        case 1:  return qsTr("启动中")
        case 2:  return qsTr("运转中")
        case 3:  return qsTr("故障")
        default: return qsTr("无数据")
        }
    }

    function engineColor() {
        if (!_efiEverSeen) {
            return qgcPal.colorGrey
        }
        if (_efiLost) {
            return qgcPal.colorRed
        }
        switch (_engineState) {
        case 2:  return qgcPal.colorGreen
        case 1:  return qgcPal.colorOrange
        case 3:  return qgcPal.colorRed
        default: return qgcPal.text
        }
    }

    function fuelColor() {
        if (!_fuelEverSeen) {
            return qgcPal.colorGrey
        }
        if (_fuelLost) {
            return qgcPal.colorRed
        }
        if (!_fuelAvailable) {
            return qgcPal.text
        }
        var pct = _fuel.percentRemaining.rawValue
        if (pct <= 15) {
            return qgcPal.colorRed
        }
        if (pct <= 30) {
            return qgcPal.colorOrange
        }
        return qgcPal.text
    }

    Row {
        id:             engineRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth / 2

        QGCColoredImage {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            width:              height
            sourceSize.width:   width
            source:             "/qmlimages/Gears.svg"
            fillMode:           Image.PreserveAspectFit
            color:              engineColor()
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel {
                text:               _engineAvailable ? _efi.rpm.rawValue.toFixed(0) + qsTr(" rpm") : qsTr("--- rpm")
                color:              engineColor()
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel {
                text:               _fuelAvailable ? qsTr("油 ") + _fuel.percentRemaining.rawValue.toFixed(0) + "%" : qsTr("油 --%")
                color:              fuelColor()
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorPopup(_root, enginePopup)
    }

    Component {
        id: enginePopup

        Rectangle {
            width:          mainLayout.width   + mainLayout.anchors.margins * 2
            height:         mainLayout.height  + mainLayout.anchors.margins * 2
            radius:         ScreenTools.defaultFontPixelHeight / 2
            color:          qgcPal.window
            border.color:   qgcPal.text

            ColumnLayout {
                id:                 mainLayout
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.top:        parent.top
                anchors.right:      parent.right
                spacing:            ScreenTools.defaultFontPixelHeight / 2

                QGCLabel {
                    Layout.alignment:   Qt.AlignCenter
                    text:               qsTr("发动机状态 (砺德 B2GH120D)")
                    font.family:        ScreenTools.demiboldFontFamily
                }

                // ----- 状态行 -----
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    spacing: ScreenTools.defaultFontPixelWidth

                    Rectangle {
                        width:  ScreenTools.defaultFontPixelHeight * 0.8
                        height: width
                        radius: width / 2
                        color:  engineColor()
                    }

                    QGCLabel {
                        text:           engineStateText()
                        font.pointSize: ScreenTools.mediumFontPointSize
                        color:          engineColor()
                    }
                }

                // ----- 链路状态 -----
                GridLayout {
                    columns:        2
                    rowSpacing:     0
                    columnSpacing:  ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel { text: qsTr("ECU 链路:") }
                    QGCLabel {
                        text:  !_efiEverSeen ? qsTr("未接入") : (_efiFresh ? qsTr("正常") : qsTr("丢失 → ECU 自动改用 PWM 备份油门"))
                        color: !_efiEverSeen ? qgcPal.colorGrey : (_efiFresh ? qgcPal.colorGreen : qgcPal.colorRed)
                    }

                    QGCLabel { text: qsTr("液位计链路:") }
                    QGCLabel {
                        text:  !_fuelEverSeen ? qsTr("未接入") : (_fuelFresh ? qsTr("正常") : qsTr("丢失"))
                        color: !_fuelEverSeen ? qgcPal.colorGrey : (_fuelFresh ? qgcPal.colorGreen : qgcPal.colorRed)
                    }
                }

                // ----- 油量条 -----
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: _fuelAvailable

                    QGCLabel {
                        text: qsTr("油量 ") + (_fuelAvailable ? _fuel.percentRemaining.rawValue.toFixed(0) + "%" : "--")
                              + ((_fuelAvailable && !isNaN(_fuel.remainingFuel.rawValue) && _fuel.maximumFuel.rawValue > 1.001)
                                 ? "  (" + (_fuel.remainingFuel.rawValue / 1000).toFixed(2) + " L / "
                                         + (_fuel.maximumFuel.rawValue / 1000).toFixed(1) + " L)"
                                 : "")
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    Rectangle {
                        Layout.fillWidth:   true
                        height:             ScreenTools.defaultFontPixelHeight * 0.7
                        radius:             3
                        color:              qgcPal.windowShade
                        border.color:       qgcPal.text

                        Rectangle {
                            anchors.left:           parent.left
                            anchors.top:            parent.top
                            anchors.bottom:         parent.bottom
                            anchors.margins:        1
                            width:                  _fuelAvailable
                                                    ? Math.max(2, (parent.width - 2) * _fuel.percentRemaining.rawValue / 100)
                                                    : 0
                            radius:                 2
                            color:                  fuelColor() === qgcPal.text ? qgcPal.colorGreen : fuelColor()
                        }
                    }
                }

                // ----- 数值表格 -----
                GridLayout {
                    columns:        2
                    rowSpacing:     0
                    columnSpacing:  ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel { text: qsTr("转速:") }
                    QGCLabel { text: _engineAvailable ? _efi.rpm.rawValue.toFixed(0) + " rpm" : "--" }

                    QGCLabel { text: qsTr("油门反馈:") }
                    QGCLabel { text: (_efiFresh && !isNaN(_efi.throttlePos.rawValue)) ? _efi.throttlePos.rawValue.toFixed(0) + " %" : "--" }

                    QGCLabel { text: qsTr("缸头温度(均值):") }
                    QGCLabel {
                        text:  (_efiFresh && !isNaN(_efi.cylinderTemp.rawValue)) ? _efi.cylinderTemp.rawValue.toFixed(0) + " °C" : "--"
                        color: (_efiFresh && _efi.cylinderTemp.rawValue > 200) ? qgcPal.colorRed : qgcPal.text
                    }

                    QGCLabel { text: qsTr("排气温度(均值):") }
                    QGCLabel {
                        text:  (_efiFresh && !isNaN(_efi.exGasTemp.rawValue)) ? _efi.exGasTemp.rawValue.toFixed(0) + " °C" : "--"
                        color: (_efiFresh && _efi.exGasTemp.rawValue > 850) ? qgcPal.colorRed : qgcPal.text
                    }

                    QGCLabel { text: qsTr("瞬时油耗:") }
                    QGCLabel { text: (_efiFresh && !isNaN(_efi.fuelFlow.rawValue)) ? _efi.fuelFlow.rawValue.toFixed(1) + " cm³/min" : "--" }

                    QGCLabel { text: qsTr("累计油耗:") }
                    QGCLabel { text: (_efiFresh && !isNaN(_efi.fuelConsumed.rawValue)) ? (_efi.fuelConsumed.rawValue / 1000).toFixed(2) + " L" : "--" }

                    QGCLabel { text: qsTr("环境压力:") }
                    QGCLabel { text: (_efiFresh && !isNaN(_efi.baroPress.rawValue)) ? _efi.baroPress.rawValue.toFixed(0) + " kPa" : "--" }

                    QGCLabel { text: qsTr("进气温度:") }
                    QGCLabel { text: (_efiFresh && !isNaN(_efi.intakeTemp.rawValue)) ? _efi.intakeTemp.rawValue.toFixed(0) + " °C" : "--" }
                }
            }
        }
    }
}
