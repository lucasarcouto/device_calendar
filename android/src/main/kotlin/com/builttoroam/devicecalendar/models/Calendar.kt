package com.builttoroam.devicecalendar.models

class Calendar(
    val id: String, 
    val syncId: String, 
    val name: String, 
    val color : Int, 
    val accountName: String, 
    val accountType: String, 
    val ownerAccount: String, 
    val visible: String,
    ) {
    var isReadOnly: Boolean = false
    var isDefault: Boolean = false
}