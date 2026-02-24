import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/sample_model.dart';
import '../../data/repositories/sample_repository.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchNotificationsTriggered extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final int sampleId;
  MarkNotificationRead(this.sampleId);

  @override
  List<Object> get props => [sampleId];
}

abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<SampleModel> approvedSamples;
  final List<int> readIds;
  final int unreadCount;

  NotificationLoaded({
    required this.approvedSamples,
    required this.readIds,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [approvedSamples, readIds, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final SampleRepository sampleRepository;

  NotificationBloc({required this.sampleRepository})
    : super(NotificationInitial()) {
    on<FetchNotificationsTriggered>(_onFetchNotifications);
    on<MarkNotificationRead>(_onMarkNotificationRead);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsTriggered event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final samples = await sampleRepository.getApprovedNotifications();
      samples.sort((a, b) => b.id.compareTo(a.id));

      final readIds = await sampleRepository.getReadNotificationIds();
      final unreadCount = samples.where((s) => !readIds.contains(s.id)).length;

      emit(
        NotificationLoaded(
          approvedSamples: samples,
          readIds: readIds,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;

      await sampleRepository.markNotificationAsRead(event.sampleId);

      final updatedReadIds = List<int>.from(currentState.readIds)
        ..add(event.sampleId);
      final newUnreadCount = currentState.approvedSamples
          .where((s) => !updatedReadIds.contains(s.id))
          .length;

      emit(
        NotificationLoaded(
          approvedSamples: currentState.approvedSamples,
          readIds: updatedReadIds,
          unreadCount: newUnreadCount,
        ),
      );
    }
  }
}
