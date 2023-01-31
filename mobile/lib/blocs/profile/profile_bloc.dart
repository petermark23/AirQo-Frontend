import 'package:app/models/models.dart';
import 'package:app/services/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/blocs/auth_code/auth_code_bloc.dart';
import 'package:app/utils/utils.dart';
import 'package:app/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState.initial()) {
    on<LogOutAccount>(_onLogOutAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<AccountDeletionCheck>(_accountDeletionCheck);
    on<EditProfile>(_onEditProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<FetchProfile>(_onFetchProfile);
    on<RefreshProfile>(_onRefreshProfile);
    on<ClearProfile>(_onClearProfile);
    on<UpdateTitle>(_onUpdateTitle);
    on<UpdateName>(_onUpdateName);
  }

  Future<Profile> _getProfile() async {
    return state.profile ?? await Profile.getProfile();
  }

  Future<void> _onUpdateName(
    UpdateName event,
    Emitter<ProfileState> emit,
  ) async {
    Profile profile = await _getProfile();
    String firstName = Profile.getNames(event.fullName).first;
    String lastName = Profile.getNames(event.fullName).last;

    return emit(state.copyWith(
      profile: profile.copyWith(firstName: firstName, lastName: lastName),
    ));
  }

  Future<void> _onUpdateTitle(
    UpdateTitle event,
    Emitter<ProfileState> emit,
  ) async {
    Profile profile = await _getProfile();

    return emit(state.copyWith(
      profile: profile.copyWith(title: event.title.value),
    ));
  }

  Future<void> _onClearProfile(
    ClearProfile _,
    Emitter<ProfileState> emit,
  ) async {
    // TODO profile.update(logout: true)
    Profile profile = await Profile.create();
    emit(const ProfileState.initial().copyWith(profile: profile));
    await HiveService.loadProfile(profile);
    await SecureStorage().clearUserData();
  }

  Future<void> _onFetchProfile(
    FetchProfile _,
    Emitter<ProfileState> emit,
  ) async {
    Profile profile = await CloudStore.getProfile();
    emit(const ProfileState.initial().copyWith(profile: profile));
    await HiveService.loadProfile(profile);
  }

  Future<void> _onRefreshProfile(
    RefreshProfile _,
    Emitter<ProfileState> emit,
  ) async {
    final hasConnection = await hasNetworkConnection();
    if (!hasConnection) {
      return emit(state.copyWith(
        blocStatus: BlocStatus.error,
        blocError: AuthenticationError.noInternetConnection,
      ));
    }
    emit(state.copyWith(blocStatus: BlocStatus.updatingData));

    final profile = await Profile.getProfile();

    return emit(state.copyWith(
      profile: profile,
      blocStatus: BlocStatus.initial,
    ));
  }

  Future<void> _onUpdateProfile(
    UpdateProfile _,
    Emitter<ProfileState> emit,
  ) async {
    Profile profile = await _getProfile();

    profile = await profile.setUserCredentials();
    emit(state.copyWith(profile: profile));
    await HiveService.updateProfile(profile);

    final hasConnection = await hasNetworkConnection();
    if (!hasConnection) {
      return;
    }
    await CloudStore.updateProfile(profile);
    // TODO background task to upload image
  }

  Future<void> _uploadPicture({
    required Emitter<ProfileState> emit,
  }) async {
    try {
      final profile = await _getProfile();

      final imageUrl = await CloudStore.uploadProfilePicture(profile.photoUrl);
      if (imageUrl.isNotEmpty) {
        // TODO verify profile updating
        emit(state.copyWith(
            profile: profile.copyWith(
          photoUrl: imageUrl,
        )));

        await Future.wait([
          CloudAnalytics.logEvent(
            Event.uploadProfilePicture,
          ),
          // TODO update profile
        ]);
      }
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }
  }

  Future<void> _onEditProfile(
    EditProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final profile = await _getProfile();

    return emit(state.copyWith(
        profile: profile.copyWith(
      firstName: event.firstName,
      lastName: event.lastName,
      photoUrl: event.photoUrl,
    )));
  }

  Future<void> _accountDeletionCheck(
    AccountDeletionCheck event,
    Emitter<ProfileState> emit,
  ) async {
    return emit(state.copyWith(
      blocStatus: event.passed
          ? BlocStatus.accountDeletionCheckSuccess
          : BlocStatus.error,
      blocError: event.passed ? AuthenticationError.none : event.error,
    ));
  }

  Future<void> _onLogOutAccount(
    LogOutAccount event,
    Emitter<ProfileState> emit,
  ) async {
    final action = await showDialog<ConfirmationAction>(
      context: event.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AuthProcedureDialog(
          authProcedure: AuthProcedure.logout,
        );
      },
    );

    if (action == null || action == ConfirmationAction.cancel) {
      return;
    }

    final bool hasConnection = await hasNetworkConnection();
    if (!hasConnection) {
      return emit(state.copyWith(
        blocStatus: BlocStatus.error,
        blocError: AuthenticationError.noInternetConnection,
      ));
    }

    emit(state.copyWith(
      blocStatus: BlocStatus.processing,
      blocError: AuthenticationError.none,
    ));

    // final successful = await AppService().authenticateUser(
    //   authProcedure: AuthProcedure.logout,
    // );
    //
    // if (successful) {
    //   event.context.read<AuthCodeBloc>().add(const ClearAuthCodeState());
    //   event.context.read<KyaBloc>().add(const ClearKya());
    //   event.context.read<AnalyticsBloc>().add(const ClearAnalytics());
    //   event.context
    //       .read<FavouritePlaceBloc>()
    //       .add(const ClearFavouritePlaces());
    //   event.context.read<NotificationBloc>().add(const ClearNotifications());
    //
    //   return emit(const AccountState.initial().copyWith(
    //     blocStatus: BlocStatus.success,
    //     blocError: AuthenticationError.none,
    //   ));
    // }

    // return emit(state.copyWith(
    //   blocStatus: BlocStatus.error,
    //   blocError: AuthenticationError.logoutFailed,
    // ));
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<ProfileState> emit,
  ) async {
    final hasConnection = await hasNetworkConnection();
    if (!hasConnection) {
      return emit(state.copyWith(
        blocStatus: BlocStatus.error,
        blocError: AuthenticationError.noInternetConnection,
      ));
    }

    final action = await showDialog<ConfirmationAction>(
      context: event.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AuthProcedureDialog(
          authProcedure: AuthProcedure.deleteAccount,
        );
      },
    );

    if (action == null || action == ConfirmationAction.cancel) {
      return;
    }

    emit(state.copyWith(
      blocStatus: BlocStatus.processing,
    ));

    final profile = await Profile.getProfile();
    final authMethod =
        profile.emailAddress == '' ? AuthMethod.phone : AuthMethod.email;

    event.context.read<AuthCodeBloc>().add(InitializeAuthCodeState(
          phoneNumber: profile.phoneNumber,
          emailAddress: profile.emailAddress,
          authProcedure: AuthProcedure.deleteAccount,
          authMethod: authMethod,
        ));

    try {
      switch (authMethod) {
        case AuthMethod.phone:
          CustomAuth.sendPhoneAuthCode(
            phoneNumber: profile.phoneNumber,
            buildContext: event.context,
            authProcedure: AuthProcedure.deleteAccount,
          );
          break;
        case AuthMethod.email:
          CustomAuth.sendEmailAuthCode(
            emailAddress: profile.emailAddress,
            buildContext: event.context,
            authProcedure: AuthProcedure.deleteAccount,
          );
          break;
        case AuthMethod.none:
          return emit(state.copyWith(
            blocStatus: BlocStatus.error,
            blocError: AuthenticationError.authFailure,
          ));
      }
    } on FirebaseAuthException catch (exception, stackTrace) {
      final authenticationError =
          CustomAuth.getFirebaseExceptionMessage(exception);
      emit(state.copyWith(
        blocError: authenticationError,
        blocStatus: BlocStatus.error,
      ));

      if (authenticationError == AuthenticationError.authFailure) {
        await logException(
          exception,
          stackTrace,
        );
      }
    } catch (exception, stackTrace) {
      emit(state.copyWith(
        blocError: AuthenticationError.authFailure,
        blocStatus: BlocStatus.error,
      ));
      await logException(
        exception,
        stackTrace,
      );
    }

    return emit(const ProfileState.initial());
  }
}