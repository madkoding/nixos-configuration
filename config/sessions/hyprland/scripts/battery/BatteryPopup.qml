import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: window

    title: "battery-popup"
    width: 420
    height: 580
    color: "transparent"

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }

    // -------------------------------------------------------------------------
    // COLORS (Catppuccin Mocha)
    // -------------------------------------------------------------------------
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    
    readonly property color mauve: "#cba6f7"
    readonly property color pink: "#f5c2e7"
    readonly property color red: "#f38ba8"
    readonly property color maroon: "#eba0ac"
    readonly property color peach: "#fab387"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"
    readonly property color teal: "#94e2d5"
    readonly property color sapphire: "#74c7ec"
    readonly property color blue: "#89b4fa"

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property int batCapacity: 0
    property string batStatus: "Unknown"
    property string powerProfile: "balanced"
    property string uptimeStr: "0h 0m"

    readonly property bool isCharging: batStatus === "Charging"

    // 1. BATTERY RING COLORS
    readonly property color batColor: {
        if (isCharging) return window.green;
        if (batCapacity >= 70) return window.green;
        if (batCapacity >= 30) return window.yellow;
        if (batCapacity >= 15) return window.peach;
        return window.red;
    }

    // 2. WINDOW AURA COLORS
    readonly property color profileStart: {
        if (powerProfile === "performance") return window.red;
        if (powerProfile === "power-saver") return window.green;
        return window.blue;
    }
    
    readonly property color profileEnd: {
        if (powerProfile === "performance") return window.maroon;
        if (powerProfile === "power-saver") return window.teal;
        return window.sapphire;
    }

    // Smooth, non-bouncy sweeping animation for the battery ring
    property real animCapacity: 0
    Behavior on animCapacity {
        NumberAnimation { duration: 1200; easing.type: Easing.OutExpo }
    }
    
    onAnimCapacityChanged: batCanvas.requestPaint()
    onBatColorChanged: batCanvas.requestPaint()

    Process {
        id: sysPoller
        command: ["sh", "-c", "echo $(cat /sys/class/power_supply/BAT0/capacity); echo $(cat /sys/class/power_supply/BAT0/status); powerprofilesctl get; awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                if (lines.length >= 4) {
                    window.batCapacity = parseInt(lines[0])
                    window.animCapacity = window.batCapacity
                    window.batStatus = lines[1]
                    window.powerProfile = lines[2]
                    window.uptimeStr = lines[3]
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: sysPoller.running = true
    }

    // -------------------------------------------------------------------------
    // STAGGERED INTRO ANIMATION CONTROLLER
    // -------------------------------------------------------------------------
    property real introState: 0.0
    Component.onCompleted: introState = 1.0
    Behavior on introState { NumberAnimation { duration: 900; easing.type: Easing.OutExpo } }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.85 + (0.15 * introState)
        opacity: introState

        // Outer Glow / Border
        Rectangle {
            anchors.fill: parent
            radius: 24
            
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: window.profileStart; Behavior on color { ColorAnimation { duration: 600; easing.type: Easing.OutQuad } } }
                GradientStop { position: 1.0; color: window.profileEnd; Behavior on color { ColorAnimation { duration: 600; easing.type: Easing.OutQuad } } }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 22
                color: window.base
                clip: true

                Rectangle {
                    anchors.fill: parent
                    opacity: 0.08
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: window.profileStart; Behavior on color { ColorAnimation { duration: 600 } } }
                        GradientStop { position: 1.0; color: window.profileEnd; Behavior on color { ColorAnimation { duration: 600 } } }
                    }
                }

                // ==========================================
                // TOP BAR
                // ==========================================
                Item {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 80
                    z: 100

                    RowLayout {
                        id: uptimeRow
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 20
                        spacing: 8
                        
                        scale: uptimeMa.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                        MouseArea {
                            id: uptimeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                        
                        Text {
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 18
                            color: uptimeMa.containsMouse ? window.mauve : window.overlay0
                            text: "󰔚"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: uptimeMa.containsMouse ? window.mauve : window.subtext0
                            text: "UP " + window.uptimeStr
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    Rectangle {
                        id: logoutBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 20
                        
                        width: logoutMa.containsMouse ? 110 : 40
                        height: 40
                        radius: 20
                        color: logoutMa.containsMouse ? "#1affffff" : "transparent"
                        border.color: logoutMa.containsMouse ? "#33ffffff" : "transparent"
                        
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        clip: true

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Text {
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 18
                                color: logoutMa.containsMouse ? window.red : window.overlay0
                                text: "󰍃"
                                rotation: logoutMa.containsMouse ? 90 : 0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            }
                            
                            Text {
                                visible: logoutBtn.width > 60
                                opacity: logoutMa.containsMouse ? 1.0 : 0.0
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: 13
                                color: window.red
                                text: "Logout"
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                        }
                        
                        MouseArea {
                            id: logoutMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Quickshell.execDetached(["sh", "-c", "loginctl terminate-user $USER"]); Qt.quit(); }
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 25

                    // ==========================================
                    // HERO: BATTERY RING
                    // ==========================================
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260
                        
                        transform: Translate { y: -30 * (1.0 - introState) }
                        opacity: introState

                        Item {
                            id: heroContainer
                            anchors.centerIn: parent
                            width: 240
                            height: 240
                            
                            rotation: -45 + (45 * introState)

                            MouseArea {
                                id: heroMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: batCanvas.requestPaint()
                                onExited: batCanvas.requestPaint()
                            }

                            property real textPulse: 0.0
                            SequentialAnimation on textPulse {
                                loops: Animation.Infinite
                                running: true
                                NumberAnimation { from: 0.0; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.0; to: 0.0; duration: 1200; easing.type: Easing.InOutSine }
                            }

                            property real pumpPhase: 0.0
                            NumberAnimation on pumpPhase {
                                running: heroMa.containsMouse && window.isCharging
                                loops: Animation.Infinite
                                from: 0.0; to: 1.0; duration: 1200
                                easing.type: Easing.InOutSine 
                                onStopped: batCanvas.requestPaint()
                            }
                            
                            property real dischargePhase: 1.0
                            NumberAnimation on dischargePhase {
                                running: heroMa.containsMouse && !window.isCharging
                                loops: Animation.Infinite
                                from: 1.0; to: 0.0; duration: 1600
                                easing.type: Easing.InOutSine
                                onStopped: batCanvas.requestPaint()
                            }
                            
                            onPumpPhaseChanged: { if(heroMa.containsMouse && window.isCharging) batCanvas.requestPaint() }
                            onDischargePhaseChanged: { if(heroMa.containsMouse && !window.isCharging) batCanvas.requestPaint() }

                            Canvas {
                                id: batCanvas
                                anchors.fill: parent
                                rotation: 180 
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    
                                    var centerX = width / 2
                                    var centerY = height / 2
                                    var radius = (width / 2) - 16
                                    var baseColorStr = window.batColor.toString()
                                    
                                    ctx.lineCap = "round"
                                    
                                    ctx.lineWidth = 14
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                    ctx.strokeStyle = "#15ffffff"
                                    ctx.stroke()
                                    
                                    var endAngle = (window.animCapacity / 100) * 2 * Math.PI

                                    ctx.lineWidth = 26
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, 0, endAngle)
                                    ctx.strokeStyle = baseColorStr
                                    ctx.globalAlpha = 0.20
                                    ctx.stroke()

                                    ctx.globalAlpha = 1.0
                                    ctx.lineWidth = 14
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, 0, endAngle)
                                    ctx.strokeStyle = baseColorStr
                                    ctx.stroke()

                                    if (heroMa.containsMouse && endAngle > 0.1) {
                                        if (window.isCharging) {
                                            var surgeCenter = heroContainer.pumpPhase * endAngle;
                                            for (var i = 0; i < 4; i++) {
                                                var spread = 0.3 + (i * 0.2); 
                                                var startA = Math.max(0, surgeCenter - spread);
                                                var endA = Math.min(endAngle, surgeCenter + spread);
                                                
                                                if (startA < endA) {
                                                    ctx.beginPath();
                                                    ctx.arc(centerX, centerY, radius, startA, endA);
                                                    ctx.lineWidth = 14 + (4 - i) * 2; 
                                                    ctx.strokeStyle = baseColorStr;
                                                    ctx.globalAlpha = 0.2 * Math.sin(heroContainer.pumpPhase * Math.PI);
                                                    ctx.stroke();
                                                }
                                            }
                                            
                                            if (heroContainer.pumpPhase > 0.7) {
                                                var flarePhase = (heroContainer.pumpPhase - 0.7) / 0.3;
                                                ctx.beginPath();
                                                var hitX = centerX + Math.cos(endAngle) * radius;
                                                var hitY = centerY + Math.sin(endAngle) * radius;
                                                
                                                ctx.arc(hitX, hitY, 7 + (flarePhase * 12), 0, 2*Math.PI);
                                                ctx.fillStyle = baseColorStr;
                                                ctx.globalAlpha = (1.0 - flarePhase) * 0.5; 
                                                ctx.fill();
                                            }
                                        } else {
                                            var drainCenter = heroContainer.dischargePhase * endAngle;
                                            for (var d = 0; d < 3; d++) {
                                                var dSpread = 0.25 + (d * 0.2);
                                                var dStart = Math.max(0, drainCenter - dSpread);
                                                var dEnd = Math.min(endAngle, drainCenter + dSpread);
                                                
                                                if (dStart < dEnd) {
                                                    ctx.beginPath();
                                                    ctx.arc(centerX, centerY, radius, dStart, dEnd);
                                                    ctx.lineWidth = 14 + (2 - d) * 1.5;
                                                    ctx.strokeStyle = Qt.lighter(window.batColor, 1.2).toString();
                                                    ctx.globalAlpha = 0.3 * Math.sin(heroContainer.dischargePhase * Math.PI);
                                                    ctx.stroke();
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 38
                                    color: heroMa.containsMouse ? Qt.lighter(window.batColor, 1.2) : window.batColor
                                    text: heroMa.containsMouse ? "󱐋" : (window.isCharging ? "󰂄" : (window.batCapacity > 20 ? "󰁹" : "󰂃"))
                                    
                                    scale: heroMa.containsMouse ? 1.15 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: 400 } }
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Black
                                    font.pixelSize: 58
                                    font.letterSpacing: -3
                                    color: heroMa.containsMouse ? window.batColor : window.text
                                    text: Math.round(window.animCapacity) + "%" 
                                    Behavior on color { ColorAnimation { duration: 400 } }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 4
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 11
                                    
                                    color: window.isCharging 
                                           ? Qt.tint(window.green, Qt.rgba(1, 1, 1, heroContainer.textPulse * 0.4)) 
                                           : Qt.tint(window.overlay0, Qt.rgba(1, 1, 1, heroContainer.textPulse * 0.15))
                                           
                                    text: window.isCharging ? "CHARGING" : "DISCHARGING"
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // POWER PROFILE SWITCHER
                    // ==========================================
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 55
                        
                        transform: Translate { y: 20 * (1.0 - introState) }
                        opacity: introState

                        Rectangle {
                            id: segmentedBg
                            anchors.centerIn: parent
                            width: 260
                            height: 55
                            radius: height / 2
                            color: "#0dffffff" 
                            border.color: "#1affffff"
                            border.width: 1

                            Rectangle {
                                id: sliderPill
                                width: segmentedBg.width / 3
                                height: segmentedBg.height
                                radius: height / 2
                                
                                x: {
                                    if (window.powerProfile === "performance") return 0;
                                    if (window.powerProfile === "balanced") return width;
                                    return width * 2;
                                }
                                Behavior on x { 
                                    NumberAnimation { duration: 400; easing.type: Easing.OutExpo } 
                                }

                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: window.profileStart; Behavior on color { ColorAnimation{duration:400} } }
                                    GradientStop { position: 1.0; color: window.profileEnd; Behavior on color { ColorAnimation{duration:400} } }
                                }
                                opacity: 0.95
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                Repeater {
                                    model: ListModel {
                                        ListElement { name: "performance"; icon: "󰓅" } 
                                        ListElement { name: "balanced"; icon: "󰗑" }   
                                        ListElement { name: "power-saver"; icon: "󰌪" } 
                                    }
                                    delegate: Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 26
                                            color: (window.powerProfile === name) ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                            text: icon
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                            
                                            scale: (window.powerProfile === name) ? 1.2 : (profileMa.containsMouse ? 1.1 : 1.0)
                                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                        }

                                        MouseArea {
                                            id: profileMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["powerprofilesctl", "set", name])
                                                sysPoller.running = true 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } 

                    // ==========================================
                    // HOLD-TO-EXECUTE ACTIONS
                    // ==========================================
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12
                        
                        transform: Translate { y: 40 * (1.0 - introState) }
                        opacity: introState
                        
                        Repeater {
                            model: ListModel {
                                ListElement { lbl: "Lock"; cmd: "hyprlock"; icon: ""; c1: "#cba6f7"; c2: "#f5c2e7" }
                                ListElement { lbl: "Sleep"; cmd: "hyprlock & systemctl suspend"; icon: "ᶻ 𝗓 𐰁"; c1: "#89b4fa"; c2: "#74c7ec" }
                                ListElement { lbl: "Reboot"; cmd: "systemctl reboot"; icon: "󰑓"; c1: "#f9e2af"; c2: "#fab387" }
                                ListElement { lbl: "Shutdown"; cmd: "systemctl poweroff"; icon: ""; c1: "#f38ba8"; c2: "#eba0ac" }
                            }
                            
                            Item {
                                id: actionCapsule
                                Layout.fillWidth: true
                                height: 55

                                scale: actionMa.pressed ? 0.94 : (actionMa.containsMouse ? 1.03 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                                property real fillLevel: 0.0
                                property bool triggered: false

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 18
                                    color: "#0dffffff"
                                }

                                Canvas {
                                    id: waveCanvas
                                    anchors.fill: parent
                                    
                                    property real wavePhase: 0.0
                                    
                                    NumberAnimation on wavePhase {
                                        running: actionCapsule.fillLevel > 0.0 && actionCapsule.fillLevel < 1.0
                                        loops: Animation.Infinite
                                        from: 0; to: Math.PI * 2
                                        duration: 800
                                    }

                                    onWavePhaseChanged: requestPaint()
                                    
                                    Connections {
                                        target: actionCapsule
                                        function onFillLevelChanged() { waveCanvas.requestPaint() }
                                    }

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);

                                        if (actionCapsule.fillLevel <= 0.001) return;

                                        var currentW = width * actionCapsule.fillLevel;
                                        var r = 18; 

                                        ctx.save();
                                        
                                        ctx.beginPath();
                                        ctx.moveTo(0, 0);
                                        
                                        if (actionCapsule.fillLevel < 0.99) {
                                            var waveAmp = 12 * Math.sin(actionCapsule.fillLevel * Math.PI); 
                                            if (currentW - waveAmp < 0) waveAmp = currentW;
                                            
                                            var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
                                            var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;

                                            ctx.lineTo(currentW, 0);
                                            ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
                                            ctx.lineTo(0, height);
                                        } else {
                                            ctx.lineTo(width, 0);
                                            ctx.lineTo(width, height);
                                            ctx.lineTo(0, height);
                                        }
                                        ctx.closePath();
                                        ctx.clip(); 

                                        ctx.beginPath();
                                        ctx.moveTo(r, 0);
                                        ctx.lineTo(width - r, 0);
                                        ctx.arcTo(width, 0, width, r, r);
                                        ctx.lineTo(width, height - r);
                                        ctx.arcTo(width, height, width - r, height, r);
                                        ctx.lineTo(r, height);
                                        ctx.arcTo(0, height, 0, height - r, r);
                                        ctx.lineTo(0, r);
                                        ctx.arcTo(0, 0, r, 0, r);
                                        ctx.closePath();

                                        var grad = ctx.createLinearGradient(0, 0, currentW, 0);
                                        grad.addColorStop(0, c1);
                                        grad.addColorStop(1, c2);
                                        ctx.fillStyle = grad;
                                        ctx.fill();

                                        ctx.restore();
                                    }
                                }
                                
                                RowLayout {
                                    id: baseTextRow
                                    anchors.centerIn: parent
                                    spacing: 10
                                    
                                    Text {
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 20
                                        color: actionMa.containsMouse ? window.text : window.subtext0
                                        text: icon
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    Text {
                                        font.family: "JetBrains Mono"
                                        font.weight: Font.Bold
                                        font.pixelSize: 13
                                        color: actionMa.containsMouse ? window.text : window.subtext0
                                        text: actionCapsule.fillLevel > 0.1 ? "Hold..." : lbl
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                Item {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: actionCapsule.width * actionCapsule.fillLevel
                                    clip: true
                                    
                                    RowLayout {
                                        x: baseTextRow.x
                                        y: baseTextRow.y
                                        width: baseTextRow.width
                                        height: baseTextRow.height
                                        spacing: 10
                                        
                                        Text {
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 20
                                            color: window.crust
                                            text: icon
                                        }
                                        
                                        Text {
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            font.pixelSize: 13
                                            color: window.crust
                                            text: actionCapsule.fillLevel > 0.1 ? "Hold..." : lbl
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 18
                                    color: "transparent"
                                    border.color: actionMa.containsMouse ? c1 : "#1affffff"
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                }

                                MouseArea {
                                    id: actionMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onPressed: { 
                                        if (!actionCapsule.triggered) {
                                            drainAnim.stop()
                                            fillAnim.start()
                                        }
                                    }
                                    onReleased: {
                                        if (!actionCapsule.triggered) {
                                            fillAnim.stop()
                                            drainAnim.start()
                                        }
                                    }
                                }

                                NumberAnimation {
                                    id: fillAnim
                                    target: actionCapsule
                                    property: "fillLevel"
                                    to: 1.0
                                    duration: 600 * (1.0 - actionCapsule.fillLevel) 
                                    easing.type: Easing.InSine
                                    onFinished: {
                                        actionCapsule.triggered = true;
                                        window.introState = 0.0;
                                        exitTimer.start();
                                    }
                                }
                                
                                NumberAnimation {
                                    id: drainAnim
                                    target: actionCapsule
                                    property: "fillLevel"
                                    to: 0.0
                                    duration: 1500 * actionCapsule.fillLevel 
                                    easing.type: Easing.OutQuad
                                }

                                Timer {
                                    id: exitTimer
                                    interval: 500 
                                    onTriggered: {
                                        Quickshell.execDetached(["sh", "-c", cmd]);
                                        Qt.quit();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
