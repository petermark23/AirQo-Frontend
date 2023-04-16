// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserNotification _$UserNotificationFromJson(Map<String, dynamic> json) =>
    UserNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      subTitle: json['sub_title'] as String? ?? '',
      image: json['image'] as String? ?? '',
      body: json['body'] as String,
      read: json['read'] as bool? ?? false,
      time: DateTime.parse(json['time'] as String),
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$UserNotificationToJson(UserNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'sub_title': instance.subTitle,
      'image': instance.image,
      'body': instance.body,
      'time': instance.time.toIso8601String(),
      'read': instance.read,
      'type': _$NotificationTypeEnumMap[instance.type]!,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.message: 'message',
  NotificationType.alert: 'alert',
};
