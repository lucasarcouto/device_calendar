/// A calendar on the user's device
class Calendar {
  /// Read-only. The unique identifier for this calendar
  String? id;

  /// Read-only. The unique ID for a row assigned by the sync source.
  String? syncId;

  /// The name of this calendar
  String? name;

  /// Read-only. If the calendar is read-only
  bool? isReadOnly;

  /// Read-only. If the calendar is the default
  bool? isDefault;

  /// Read-only. Color of the calendar
  int? color;

  /// Read-only. Account name associated with the calendar
  String? accountName;

  /// Read-only. Account type associated with the calendar
  String? accountType;

  /// Read-only. Is the calendar selected to be displayed? 0 - do not show events associated with this calendar. 1 - show events associated with this calendar
  String? visible;

  Calendar(
      {this.id,
      this.syncId,
      this.name,
      this.isReadOnly,
      this.isDefault,
      this.color,
      this.accountName,
      this.accountType,
      this.visible});

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    syncId = json['syncId'];
    name = json['name'];
    isReadOnly = json['isReadOnly'];
    isDefault = json['isDefault'];
    color = json['color'];
    accountName = json['accountName'];
    accountType = json['accountType'];
    visible = json['visible'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'syncId': syncId,
      'name': name,
      'isReadOnly': isReadOnly,
      'isDefault': isDefault,
      'color': color,
      'accountName': accountName,
      'accountType': accountType,
      'visible': visible
    };

    return data;
  }
}
