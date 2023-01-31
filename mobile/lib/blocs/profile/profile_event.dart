part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
}

class FetchProfile extends ProfileEvent {
  const FetchProfile();
  @override
  List<Object?> get props => [];
}

class ClearProfile extends ProfileEvent {
  const ClearProfile();
  @override
  List<Object?> get props => [];
}

class RefreshProfile extends ProfileEvent {
  const RefreshProfile();
  @override
  List<Object?> get props => [];
}

class LogOutAccount extends ProfileEvent {
  const LogOutAccount({
    required this.context,
  });
  final BuildContext context;
  @override
  List<Object?> get props => [];
}

class DeleteAccount extends ProfileEvent {
  const DeleteAccount({
    required this.context,
  });
  final BuildContext context;

  @override
  List<Object?> get props => [];
}

class AccountDeletionCheck extends ProfileEvent {
  const AccountDeletionCheck({
    this.error,
    required this.passed,
  });

  final bool passed;
  final AuthenticationError? error;
  @override
  List<Object?> get props => [passed, error];
}

class EditProfile extends ProfileEvent {
  const EditProfile({
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  final String? firstName;
  final String? lastName;
  final String? photoUrl;

  @override
  List<Object?> get props => [firstName, lastName, photoUrl];
}

class UpdateProfile extends ProfileEvent {
  const UpdateProfile();

  @override
  List<Object?> get props => [];
}

class UpdateTitle extends ProfileEvent {
  const UpdateTitle(this.title);
  final TitleOptions title;

  @override
  List<Object?> get props => [];
}

class UpdateName extends ProfileEvent {
  const UpdateName(this.fullName);
  final String fullName;

  @override
  List<Object?> get props => [];
}