import 'dart:async';

import 'package:app/models/models.dart';
import 'package:app/services/services.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'notification_event.dart';

class NotificationBloc
    extends HydratedBloc<NotificationEvent, List<UserNotification>> {
  NotificationBloc() : super([]) {
    on<ClearNotifications>(_onClearNotifications);
    on<SyncNotifications>(_onSyncNotifications);
  }

  Future<void> _onSyncNotifications(
    SyncNotifications _,
    Emitter<List<UserNotification>> emit,
  ) async {
    Set<UserNotification> notificationsSet = state.toSet();

    List<UserNotification> notifications = await CloudStore.getNotifications();

    if (notifications.isNotEmpty) {
      notificationsSet
          .retainWhere((element) => notifications.contains(element));
    }
    notificationsSet.addAll(notifications.toSet());
    emit(notificationsSet.toList());
  }

  void _onClearNotifications(
    ClearNotifications _,
    Emitter<List<UserNotification>> emit,
  ) {
    emit([]);
  }

  @override
  List<UserNotification>? fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> notifications =
        json["notifications"] as List<Map<String, dynamic>>;
    return notifications.map((e) => UserNotification.fromJson(e)).toList();
  }

  @override
  Map<String, dynamic>? toJson(List<UserNotification> state) {
    List<Map<String, dynamic>> notifications =
        state.map((e) => e.toJson()).toList();
    return {
      "notifications": notifications,
    };
  }
}
