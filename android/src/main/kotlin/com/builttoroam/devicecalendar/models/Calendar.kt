package com.builttoroam.devicecalendar.models

class Calendar(val id: String, val name: String, val color : Int, val accountName: String, val accountType: String, val visible: String) {
    var isReadOnly: Boolean = false
    var isDefault: Boolean = false
}