import QtQuick 2.0
import SddmComponents 2.0

// base16-mreq dark theme
// base00 #181818  base01 #282828  base02 #383838  base03 #585858
// base04 #b8b8b8  base05 #d8d8d8  base07 #f8f8f8
// base08 #ab4642  base0B #a1b56c  base0D #7cafc2

Rectangle {
    id: container
    width: 640
    height: 480
    color: "#181818"

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            statusText.color = "#a1b56c"
            statusText.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            passwordField.text = ""
            passwordField.forceActiveFocus()
            statusText.color = "#ab4642"
            statusText.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            statusText.color = "#ab4642"
            statusText.text = message
        }
    }

    Column {
        id: formColumn
        anchors.centerIn: parent
        width: 380
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: sddm.hostName
            color: "#f8f8f8"
            font.pixelSize: 22
            font.bold: true
        }

        // Username
        Column {
            width: parent.width
            spacing: 6
            Text {
                text: textConstants.userName
                color: "#b8b8b8"
                font.pixelSize: 13
            }
            Rectangle {
                width: parent.width
                height: 36
                color: "#282828"
                radius: 3
                border.color: usernameField.activeFocus ? "#585858" : "transparent"
                border.width: 1
                TextInput {
                    id: usernameField
                    x: 10
                    width: parent.width - 20
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    text: userModel.lastUser
                    color: "#f8f8f8"
                    font.pixelSize: 15
                    selectionColor: "#585858"
                    selectedTextColor: "#f8f8f8"
                    clip: true
                    KeyNavigation.tab: passwordField
                    Keys.onReturnPressed: sddm.login(usernameField.text, passwordField.text, sessionModel.lastIndex)
                }
            }
        }

        // Password
        Column {
            width: parent.width
            spacing: 6
            Text {
                text: textConstants.password
                color: "#b8b8b8"
                font.pixelSize: 13
            }
            Rectangle {
                width: parent.width
                height: 36
                color: "#282828"
                radius: 3
                border.color: passwordField.activeFocus ? "#585858" : "transparent"
                border.width: 1
                TextInput {
                    id: passwordField
                    x: 10
                    width: parent.width - 20
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: "#f8f8f8"
                    font.pixelSize: 15
                    selectionColor: "#585858"
                    selectedTextColor: "#f8f8f8"
                    clip: true
                    KeyNavigation.backtab: usernameField
                    Keys.onReturnPressed: sddm.login(usernameField.text, passwordField.text, sessionModel.lastIndex)
                }
            }
        }

        // Status / error line
        Text {
            id: statusText
            width: parent.width
            text: ""
            color: "#585858"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        // Login button
        Rectangle {
            width: parent.width
            height: 36
            color: loginArea.pressed ? "#383838" : "#585858"
            radius: 3
            Text {
                anchors.centerIn: parent
                text: textConstants.login
                color: "#f8f8f8"
                font.pixelSize: 15
            }
            MouseArea {
                id: loginArea
                anchors.fill: parent
                onClicked: sddm.login(usernameField.text, passwordField.text, sessionModel.lastIndex)
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    // Shutdown / reboot
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        spacing: 28
        Text {
            text: textConstants.shutdown
            color: "#585858"
            font.pixelSize: 13
            MouseArea {
                anchors.fill: parent
                onClicked: sddm.powerOff()
                cursorShape: Qt.PointingHandCursor
            }
        }
        Text {
            text: textConstants.reboot
            color: "#585858"
            font.pixelSize: 13
            MouseArea {
                anchors.fill: parent
                onClicked: sddm.reboot()
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    Component.onCompleted: {
        if (usernameField.text === "")
            usernameField.forceActiveFocus()
        else
            passwordField.forceActiveFocus()
    }
}
