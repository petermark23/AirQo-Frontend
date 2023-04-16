import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'enum_constants.dart';

part 'notification.g.dart';

@JsonSerializable()
class UserNotification extends Equatable {
  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      _$UserNotificationFromJson(json);

  const UserNotification({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.image,
    required this.body,
    required this.read,
    required this.time,
    required this.type,
  });

  @JsonKey()
  final String id;

  @JsonKey()
  final String title;

  @JsonKey(name: "sub_title", defaultValue: "")
  final String subTitle;

  @JsonKey(defaultValue: "")
  final String image;

  @JsonKey()
  final String body;

  @JsonKey()
  final DateTime time;

  @JsonKey(defaultValue: false)
  final bool read;

  @JsonKey()
  final NotificationType type;

  Map<String, dynamic> toJson() => _$UserNotificationToJson(this);

  @override
  List<Object?> get props => [id, read,];
}
