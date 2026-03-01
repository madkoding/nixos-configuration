import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: musicWindow

    title: "music_win"
    width: 700
    height: 620
    color: "transparent"

    // -------------------------------------------------------------------------
    // DIRECTORIES & CONFIG
    // -------------------------------------------------------------------------
    // Reverting to Quickshell.env to ensure the path is absolute and valid
    readonly property string scriptDir: Quickshell.env("HOME") + "/.config/eww/bar/scripts"

    QtObject {
        id: colors
        readonly property color base: "#1e1e2e"
        readonly property color surface0: "#313244"
        readonly property color surface1: "#45475a"
        readonly property color text: "#cdd6f4"
        readonly property color subtext0: "#a6adc8"
        readonly property color overlay1: "#7f849c"
        readonly property color overlay2: "#9399b2"
        readonly property color mauve: "#cba6f7"
        readonly property color pink: "#f5c2e7"
        readonly property color red: "#f38ba8"
        readonly property color blue: "#89b4fa"
        readonly property color sapphire: "#74c7ec"
        readonly property color lavender: "#b4befe"
        readonly property color yellow: "#f9e2af"
    }

    // Default safe objects
    property var musicFull: ({
        title: "Not Playing", artist: "", status: "Stopped", percent: 0, length: 0,
        lengthStr: "00:00", positionStr: "00:00", timeStr: "--:-- / --:--",
        source: "Offline", playerName: "", blur: "", textColor: "#cdd6f4", 
        deviceIcon: "󰓃", deviceName: "Speaker", artUrl: ""
    })

    property var eqData: ({
        b1: 0, b2: 0, b3: 0, b4: 0, b5: 0, b6: 0, b7: 0, b8: 0, b9: 0, b10: 0,
        preset: "Flat", pending: "false"
    })

    // -------------------------------------------------------------------------
    // BOMB-PROOF PROCESS POLLERS
    // -------------------------------------------------------------------------
    Process {
        id: musicPoll
        command: ["bash", "-c", musicWindow.scriptDir + "/music_info.sh"]
        onExited: {
            try { 
                // 1. Log errors if the bash script fails
                if (stderr) {
                    let errOut = Array.isArray(stderr) ? stderr.join("\n") : stderr.toString();
                    if (errOut.trim() !== "") console.log("Music Script Bash Error:", errOut);
                }

                // 2. Safely parse stdout only if it actually exists
                if (stdout !== null && stdout !== undefined) {
                    let rawOut = Array.isArray(stdout) ? stdout.join("\n") : stdout.toString();
                    let out = rawOut.trim();
                    
                    if (out !== "") {
                        let parsed = JSON.parse(out);
                        if (parsed !== null && typeof parsed === 'object') {
                            musicWindow.musicFull = parsed;
                        }
                    }
                }
            } catch(e) {
                console.log("CRITICAL ERROR Parsing Music JSON:", e);
            }
        }
    }
    Timer { 
        interval: 200; running: true; repeat: true; 
        onTriggered: if (!musicPoll.running) musicPoll.running = true 
    }

    Process {
        id: eqPoll
        command: ["bash", "-c", musicWindow.scriptDir + "/equalizer.sh get"]
        onExited: {
            try { 
                if (stderr) {
                    let errOut = Array.isArray(stderr) ? stderr.join("\n") : stderr.toString();
                    if (errOut.trim() !== "") console.log("EQ Script Bash Error:", errOut);
                }

                if (stdout !== null && stdout !== undefined) {
                    let rawOut = Array.isArray(stdout) ? stdout.join("\n") : stdout.toString();
                    let out = rawOut.trim();
                    
                    if (out !== "") {
                        let parsed = JSON.parse(out);
                        if (parsed !== null && typeof parsed === 'object') {
                            musicWindow.eqData = parsed;
                        }
                    }
                }
            } catch(e) {
                console.log("CRITICAL ERROR Parsing EQ JSON:", e);
            }
        }
    }
    Timer { 
        interval: 200; running: true; repeat: true; 
        onTriggered: if (!eqPoll.running) eqPoll.running = true 
    }

    // -------------------------------------------------------------------------
    // ROOT UI
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: 14
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: colors.mauve }
                GradientStop { position: 0.5; color: colors.blue }
                GradientStop { position: 1.0; color: colors.pink }
            }
            RotationAnimation on rotation { from: 0; to: 360; duration: 5000; loops: Animation.Infinite }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3 
            radius: 12
            color: colors.base
            clip: true

            Image {
                anchors.fill: parent
                source: musicWindow.musicFull.blur !== "" ? "file://" + musicWindow.musicFull.blur : ""
                fillMode: Image.PreserveAspectCrop
                opacity: 0.6
                asynchronous: true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    spacing: 25

                    Item {
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 220
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            id: vinylMask
                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                        }

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: musicWindow.musicFull.artUrl !== "" ? "file://" + musicWindow.musicFull.artUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            asynchronous: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: coverImage
                            maskEnabled: true
                            maskSource: vinylMask
                            
                            shadowEnabled: true
                            shadowColor: colors.mauve
                            shadowBlur: 1.0
                            shadowOpacity: musicWindow.musicFull.status === "Playing" ? 0.6 : 0.0

                            RotationAnimation on rotation {
                                from: 0; to: 360; duration: 4000; loops: Animation.Infinite
                                running: musicWindow.musicFull.status === "Playing"
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 40; height: 40
                            radius: 20
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.color: colors.surface1
                            border.width: 4
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 15

                        ColumnLayout {
                            spacing: 6
                            Text {
                                text: musicWindow.musicFull.title
                                color: musicWindow.musicFull.textColor
                                font.pixelSize: 20
                                font.weight: Font.Black
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                            }
                            Text {
                                text: "BY " + musicWindow.musicFull.artist
                                color: colors.pink
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            RowLayout {
                                spacing: 10
                                Rectangle {
                                    color: Qt.rgba(255/255, 255/255, 255/255, 0.1)
                                    radius: 4
                                    implicitWidth: pillLayout.implicitWidth + 20
                                    implicitHeight: pillLayout.implicitHeight + 8
                                    RowLayout {
                                        id: pillLayout
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: musicWindow.musicFull.deviceIcon; color: colors.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: 14 }
                                        Text { text: musicWindow.musicFull.deviceName; color: colors.overlay2; font.pixelSize: 12; font.weight: Font.ExtraBold }
                                    }
                                }
                                Text {
                                    text: "VIA " + musicWindow.musicFull.source
                                    color: colors.yellow
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    font.italic: true
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            
                            Slider {
                                id: progressBar
                                Layout.fillWidth: true
                                from: 0; to: 100
                                
                                Connections {
                                    target: musicWindow
                                    function onMusicFullChanged() {
                                        if (!progressBar.pressed) {
                                            progressBar.value = musicWindow.musicFull.percent;
                                        }
                                    }
                                }

                                onPressedChanged: {
                                    if (!pressed) {
                                        let cmd = musicWindow.scriptDir + "/player_control.sh seek " + Math.round(value) + " " + musicWindow.musicFull.length + " '" + musicWindow.musicFull.playerName + "'";
                                        Quickshell.execDetached(["bash", "-c", cmd]);
                                    }
                                }

                                background: Rectangle {
                                    x: progressBar.leftPadding
                                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                                    implicitWidth: 200
                                    implicitHeight: 8
                                    width: progressBar.availableWidth
                                    height: implicitHeight
                                    radius: 4
                                    color: Qt.rgba(17/255, 17/255, 27/255, 0.6)

                                    Rectangle {
                                        width: progressBar.visualPosition * parent.width
                                        height: parent.height
                                        color: colors.blue
                                        radius: 4
                                    }
                                }

                                handle: Rectangle {
                                    x: progressBar.leftPadding + progressBar.visualPosition * (progressBar.availableWidth - width)
                                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    radius: 7
                                    color: colors.text
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: musicWindow.musicFull.positionStr; color: colors.overlay2; font.pixelSize: 13; font.weight: Font.Bold; Layout.alignment: Qt.AlignLeft }
                                Item { Layout.fillWidth: true }
                                Text { text: musicWindow.musicFull.lengthStr; color: colors.overlay2; font.pixelSize: 13; font.weight: Font.Bold; Layout.alignment: Qt.AlignRight }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 30

                            MouseArea {
                                implicitWidth: 30; implicitHeight: 30; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", "playerctl -p '" + musicWindow.musicFull.playerName + "' previous"])
                                Text { anchors.centerIn: parent; text: ""; color: parent.containsMouse ? colors.text : colors.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: 24 }
                            }
                            MouseArea {
                                implicitWidth: 50; implicitHeight: 50; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", "playerctl -p '" + musicWindow.musicFull.playerName + "' play-pause"])
                                Text { anchors.centerIn: parent; text: musicWindow.musicFull.status === "Playing" ? "" : ""; color: parent.containsMouse ? colors.pink : colors.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: 42 }
                            }
                            MouseArea {
                                implicitWidth: 30; implicitHeight: 30; cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", "playerctl -p '" + musicWindow.musicFull.playerName + "' next"])
                                Text { anchors.centerIn: parent; text: ""; color: parent.containsMouse ? colors.text : colors.overlay2; font.family: "Iosevka Nerd Font"; font.pixelSize: 24 }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    color: Qt.rgba(255/255, 255/255, 255/255, 0.1)
                    radius: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Equalizer"; color: colors.mauve; font.pixelSize: 16; font.weight: Font.Black; Layout.fillWidth: true }
                        
                        Rectangle {
                            color: musicWindow.eqData.pending === "true" || musicWindow.eqData.pending === true ? Qt.rgba(243/255, 139/255, 168/255, 0.1) : "transparent"
                            border.color: musicWindow.eqData.pending === "true" || musicWindow.eqData.pending === true ? colors.red : "transparent"
                            radius: 6
                            implicitWidth: 60; implicitHeight: 24
                            
                            Text { 
                                anchors.centerIn: parent
                                text: musicWindow.eqData.pending === "true" || musicWindow.eqData.pending === true ? "Apply" : "Saved"
                                color: musicWindow.eqData.pending === "true" || musicWindow.eqData.pending === true ? colors.red : colors.overlay1
                                font.pixelSize: 11; font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["bash", "-c", musicWindow.scriptDir + "/equalizer.sh apply"])
                            }
                        }

                        Text { text: musicWindow.eqData.preset; color: colors.subtext0; font.pixelSize: 14; font.weight: Font.Bold; Layout.leftMargin: 15 }
                    }

                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150

                        Repeater {
                            model: [
                                {idx: "1", lbl: "31"}, {idx: "2", lbl: "63"}, {idx: "3", lbl: "125"},
                                {idx: "4", lbl: "250"}, {idx: "5", lbl: "500"}, {idx: "6", lbl: "1k"},
                                {idx: "7", lbl: "2k"}, {idx: "8", lbl: "4k"}, {idx: "9", lbl: "8k"},
                                {idx: "10", lbl: "16k"}
                            ]
                            delegate: Item {
                                width: parent.width / 10
                                height: parent.height

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 5

                                    Slider {
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignHCenter
                                        orientation: Qt.Vertical
                                        from: 12; to: -12 
                                        
                                        value: musicWindow.eqData["b" + modelData.idx] !== undefined ? musicWindow.eqData["b" + modelData.idx] : 0
                                        
                                        onMoved: {
                                            Quickshell.execDetached(["bash", "-c", musicWindow.scriptDir + "/equalizer.sh set_band " + modelData.idx + " " + Math.round(value)])
                                        }

                                        background: Rectangle {
                                            x: parent.width / 2 - width / 2
                                            y: parent.topPadding
                                            implicitWidth: 6
                                            implicitHeight: 150
                                            width: implicitWidth
                                            height: parent.availableHeight
                                            radius: 3
                                            color: Qt.rgba(17/255, 17/255, 27/255, 0.6)

                                            Rectangle {
                                                width: parent.width
                                                height: parent.height * parent.parent.visualPosition
                                                color: colors.blue
                                                radius: 3
                                                anchors.bottom: parent.bottom
                                            }
                                        }
                                        handle: Rectangle {
                                            x: parent.width / 2 - width / 2
                                            y: parent.topPadding + parent.visualPosition * (parent.availableHeight - height)
                                            implicitWidth: 14; implicitHeight: 14; radius: 7
                                            color: colors.text
                                        }
                                    }
                                    Text { text: modelData.lbl; color: colors.overlay1; font.pixelSize: 10; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: ["Flat", "Bass", "Treble", "Vocal"]
                                delegate: presetButtonDelegate
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: ["Pop", "Rock", "Jazz", "Classic"]
                                delegate: presetButtonDelegate
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: presetButtonDelegate
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: 8
            
            color: musicWindow.eqData.preset === modelData ? colors.mauve : Qt.rgba(30/255, 30/255, 46/255, 0.75)
            
            Text {
                anchors.centerIn: parent
                text: modelData
                color: musicWindow.eqData.preset === modelData ? colors.base : colors.subtext0
                font.pixelSize: 12
                font.weight: Font.ExtraBold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["bash", "-c", musicWindow.scriptDir + "/equalizer.sh preset " + modelData])
            }
        }
    }
}
