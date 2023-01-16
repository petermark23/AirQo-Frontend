import 'dart:io';

import 'package:app/blocs/blocs.dart';
import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/services/services.dart';
import 'package:app/utils/utils.dart';
import 'package:app/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CloudAnalytics {
  static Future<bool> logEvent(Event analyticsEvent) async {
    await FirebaseAnalytics.instance.logEvent(
      name: analyticsEvent.snakeCase(),
    );

    return true;
  }

  static Future<void> logAppRating() async {
    await CloudAnalytics.logEvent(
      Event.rateApp,
    );
  }

  static Future<void> logSignUpEvents() async {
    // TODO add to final on boarding screen
    try {
      await Future.wait([
        logEvent(Event.createUserProfile),
        logNetworkProvider(),
        logPlatformType(),
        logGender(),
      ]);
    } catch (exception, stackTrace) {
      debugPrint('$exception\n$stackTrace');
    }
  }

  static Future<void> logSignInEvents() async {
    // TODO add to final on boarding screen
    try {
      await Future.wait([
        logPlatformType(),
      ]);
    } catch (exception, stackTrace) {
      debugPrint('$exception\n$stackTrace');
    }
  }

  static Future<void> logAirQualitySharing() async {
    final profile = Hive.box<Profile>(HiveBox.profile).getAt(0);
    if (profile != null) {
      profile.preferences.aqShares = profile.preferences.aqShares + 1;
      if (profile.preferences.aqShares >= 5) {
        await CloudAnalytics.logEvent(
          Event.shareAirQualityInformation,
        );
      }
    }
  }

  static Future<void> logNetworkProvider() async {
    final profile = Hive.box<Profile>(HiveBox.profile).getAt(0);
    if (profile != null) {
      final carrier = await AirqoApiClient().getCarrier(profile.phoneNumber);
      if (carrier.toLowerCase().contains('airtel')) {
        await logEvent(Event.airtelUser);
      } else if (carrier.toLowerCase().contains('mtn')) {
        await logEvent(Event.mtnUser);
      } else {
        await logEvent(
          Event.otherNetwork,
        );
      }
    }
  }

  static Future<void> logPlatformType() async {
    if (Platform.isAndroid) {
      await logEvent(
        Event.androidUser,
      );
    } else if (Platform.isIOS) {
      await logEvent(
        Event.iosUser,
      );
    } else {
      debugPrint('Unknown Platform');
    }
  }

  static Future<void> logGender() async {
    final profile = Hive.box<Profile>(HiveBox.profile).getAt(0);
    if (profile != null) {
      if (profile.gender() == Gender.male) {
        await logEvent(
          Event.maleUser,
        );
      } else if (profile.gender() == Gender.female) {
        await logEvent(
          Event.femaleUser,
        );
      } else {
        await logEvent(
          Event.undefinedGender,
        );
      }
    }
  }
}

class CloudStore {
  static Future<List<Kya>> getKya() async {
    List<Kya> kya = <Kya>[];
    final kyaCollection =
        await FirebaseFirestore.instance.collection(Config.kyaCollection).get();

    for (final doc in kyaCollection.docs) {
      try {
        final kyaData = doc.data();
        if (kyaData.isEmpty) {
          continue;
        }
        kya.add(Kya.fromJson(kyaData));
      } catch (exception, stackTrace) {
        logException(exception, stackTrace);
      }
    }

    final userId = CustomAuth.getUserId();
    List<KyaProgress> userProgress = <KyaProgress>[];
    final kyaProgressCollection = await FirebaseFirestore.instance
        .collection(Config.usersKyaCollection)
        .doc(userId)
        .collection(userId)
        .get();

    for (final doc in kyaProgressCollection.docs) {
      try {
        userProgress.add(KyaProgress.fromJson(doc.data()));
      } catch (exception, stackTrace) {
        debugPrint('$exception\n$stackTrace');
      }
    }

    kya = kya.map((element) {
      KyaProgress kyaProgress =
          userProgress.firstWhere((x) => x.id == element.id, orElse: () {
        return KyaProgress(id: element.id, progress: 0);
      });
      return element.copyWith(progress: kyaProgress.progress);
    }).toList();

    return kya;
  }

  static Future<List<AppNotification>> getNotifications() async {
    final userId = CustomAuth.getUserId();
    final notifications = <AppNotification>[];

    try {
      final notificationsCollection = await FirebaseFirestore.instance
          .collection(Config.usersNotificationCollection)
          .doc(userId)
          .collection(userId)
          .get();

      for (final doc in notificationsCollection.docs) {
        try {
          notifications.add(AppNotification.fromJson(doc.data()));
        } catch (exception, stackTrace) {
          await logException(
            exception,
            stackTrace,
          );
        }
      }
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return notifications;
  }

  static Future<List<Analytics>> getCloudAnalytics() async {
    String uid = CustomAuth.getUserId();
    List<Analytics> analytics = <Analytics>[];

    try {
      final analyticsCollection = await FirebaseFirestore.instance
          .collection(Config.usersKyaCollection)
          .doc(uid)
          .collection(uid)
          .get();

      for (final doc in analyticsCollection.docs) {
        try {
          analytics.add(Analytics.fromJson(doc.data()));
        } catch (exception, stackTrace) {
          await logException(
            exception,
            stackTrace,
          );
        }
      }
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return analytics;
  }

  static Future<Profile> getProfile() async {
    Profile profile;

    try {
      final userJson = await FirebaseFirestore.instance
          .collection(Config.usersCollection)
          .doc(CustomAuth.getUserId())
          .get();

      if (userJson.data() == null) {
        profile = await Profile.create();
        await updateProfile(profile);
      } else {
        profile = Profile.fromJson(userJson.data()!);
      }
    } catch (exception, stackTrace) {
      profile = await Profile.create();
      await updateProfile(profile);
      await logException(
        exception,
        stackTrace,
      );
    }
    profile.user = CustomAuth.getUser();
    return profile;
  }

  static Future<List<FavouritePlace>> getFavouritePlaces() async {
    final favouritePlaces = <FavouritePlace>[];

    try {
      final userId = CustomAuth.getUserId();

      final jsonObject = await FirebaseFirestore.instance
          .collection(Config.favPlacesCollection)
          .doc(userId)
          .collection(userId)
          .get();

      for (final doc in jsonObject.docs) {
        try {
          favouritePlaces.add(FavouritePlace.fromFirestore(doc));
        } catch (exception, stackTrace) {
          await logException(exception, stackTrace);
        }
      }
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return favouritePlaces;
  }

  static Future<bool> updateFavouritePlaces() async {
    final hasConnection = await hasNetworkConnection();
    final userId = CustomAuth.getUserId();
    if (!hasConnection || userId.trim().isEmpty) {
      return true;
    }

    final batch = FirebaseFirestore.instance.batch();

    final cloudFavPlaces = await getFavouritePlaces();
    for (final favouritePlace in cloudFavPlaces) {
      try {
        final document = FirebaseFirestore.instance
            .collection(Config.favPlacesCollection)
            .doc(userId)
            .collection(userId)
            .doc(favouritePlace.placeId);
        batch.delete(document);
      } catch (exception, stackTrace) {
        await logException(
          exception,
          stackTrace,
        );
      }
    }

    final favouritePlaces =
        Hive.box<FavouritePlace>(HiveBox.favouritePlaces).values.toList();
    for (final favouritePlace in favouritePlaces) {
      try {
        final document = FirebaseFirestore.instance
            .collection(Config.favPlacesCollection)
            .doc(userId)
            .collection(userId)
            .doc(favouritePlace.placeId);
        batch.set(
          document,
          favouritePlace.toJson(),
        );
      } catch (exception, stackTrace) {
        await logException(
          exception,
          stackTrace,
        );
      }
    }

    batch.commit();

    return true;
  }

  static Future<void> updateProfile(Profile profile) async {
    final currentUser = CustomAuth.getUser();
    if (currentUser == null || CustomAuth.isGuestUser()) {
      return;
    }
    try {
      try {
        await Future.wait([
          currentUser.updateDisplayName(profile.firstName),
          FirebaseFirestore.instance
              .collection(Config.usersCollection)
              .doc(profile.userId)
              .update(
                profile.toJson(),
              ),
        ]);
      } catch (exception) {
        await Future.wait([
          currentUser.updateDisplayName(profile.firstName),
          FirebaseFirestore.instance
              .collection(Config.usersCollection)
              .doc(profile.userId)
              .set(
                profile.toJson(),
              ),
        ]);
      }
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }
  }

  static Future<bool> updateCloudAnalytics() async {
    final currentUser = CustomAuth.getUser();
    if (currentUser == null) {
      return true;
    }
    try {
      final analytics = Hive.box<Analytics>(HiveBox.analytics)
          .values
          .toList()
          .cast<Analytics>();
      final profile = await Profile.getProfile();
      for (final x in analytics) {
        try {
          await FirebaseFirestore.instance
              .collection(Config.usersAnalyticsCollection)
              .doc(profile.userId)
              .collection(profile.userId)
              .doc(x.site)
              .set(
                x.toJson(),
              );
        } catch (exception) {
          debugPrint(exception.toString());
        }
      }
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return true;
  }

  static Future<void> updateCloudNotification(
    AppNotification notification,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final profile = await Profile.getProfile();
        try {
          await FirebaseFirestore.instance
              .collection(Config.usersNotificationCollection)
              .doc(profile.userId)
              .collection(profile.userId)
              .doc(notification.id)
              .update(
                notification.toJson(),
              );
        } catch (exception) {
          await FirebaseFirestore.instance
              .collection(Config.usersNotificationCollection)
              .doc(profile.userId)
              .collection(profile.userId)
              .doc(notification.id)
              .set(
                notification.toJson(),
              );
        }
      } catch (exception, stackTrace) {
        await logException(
          exception,
          stackTrace,
        );
      }
    }
  }

  static Future<void> updateKyaProgress(Kya kya) async {
    final userId = CustomAuth.getUserId();
    KyaProgress progress = KyaProgress.fromKya(kya);

    try {
      await FirebaseFirestore.instance
          .collection(Config.usersKyaCollection)
          .doc(userId)
          .collection(userId)
          .doc(progress.id)
          .set(progress.toJson());
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }
  }

  static Future<String> uploadProfilePicture(String filePath) async {
    try {
      final userId = CustomAuth.getUserId();
      final file = File(filePath);

      final docRef = '${Config.usersProfilePictureStorage}/'
          '$userId/avatar${file.getExtension()}';

      final task = await firebase_storage.FirebaseStorage.instance
          .ref(docRef)
          .putFile(file);

      return await task.storage.ref(docRef).getDownloadURL();
    } on Exception catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return '';
  }
}

class CloudMessaging {
  static Future<String?> getDeviceToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}

class CustomAuth {
  static Future<Profile> createProfile() async {
    final profile = await Profile.create();

    try {
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(profile.firstName);
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return profile;
  }

  static Future<bool> firebaseSignIn(AuthCredential? authCredential) async {
    UserCredential userCredential;
    if (authCredential == null) {
      User? user = getUser();

      if (user != null && user.isAnonymous) {
        return true;
      }

      userCredential = await FirebaseAuth.instance.signInAnonymously();
    } else {
      User? user = getUser();
      userCredential = user == null
          ? await FirebaseAuth.instance.signInWithCredential(authCredential)
          : await user.linkWithCredential(authCredential);
    }

    return userCredential.user != null;
  }

  static Future<bool> firebaseSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
      return false;
    }

    return true;
  }

  static User? getUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static String getUserId() {
    User? user = getUser();
    return user == null ? '' : user.uid;
  }

  static bool isLoggedIn() {
    return getUser() != null;
  }

  static bool isGuestUser() {
    final user = getUser();
    if (user == null) {
      return true;
    }

    return user.isAnonymous;
  }

  static Future<bool> reAuthenticate(AuthCredential authCredential) async {
    final userCredential = await FirebaseAuth.instance.currentUser!
        .reauthenticateWithCredential(authCredential);

    return userCredential.user != null;
  }

  static AuthenticationError getFirebaseErrorCodeMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthenticationError.invalidEmailAddress;
      case 'email-already-in-use':
        return AuthenticationError.emailTaken;
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return AuthenticationError.accountTaken;
      case 'invalid-verification-code':
        return AuthenticationError.invalidAuthCode;
      case 'invalid-phone-number':
        return AuthenticationError.invalidPhoneNumber;
      case 'session-expired':
      case 'expired-action-code':
        return AuthenticationError.authSessionTimeout;
      case 'user-disabled':
      case 'user-mismatch':
      case 'user-not-found':
        return AuthenticationError.accountInvalid;
      case 'requires-recent-login':
        return AuthenticationError.logInRequired;
      case 'invalid-verification-id':
      case 'invalid-credential':
      case 'missing-client-identifier':
      default:
        return AuthenticationError.authFailure;
    }
  }

  static Future<void> sendPhoneAuthCode({
    required String phoneNumber,
    required BuildContext buildContext,
    required AuthProcedure authProcedure,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        switch (authProcedure) {
          case AuthProcedure.login:
          case AuthProcedure.signup:
            buildContext
                .read<PhoneAuthBloc>()
                .add(const UpdateStatus(BlocStatus.success));
            break;
          case AuthProcedure.deleteAccount:
            buildContext
                .read<AccountBloc>()
                .add(const AccountDeletionCheck(passed: true));
            break;
          case AuthProcedure.anonymousLogin:
          case AuthProcedure.logout:
          case AuthProcedure.none:
            break;
        }

        buildContext
            .read<AuthCodeBloc>()
            .add(VerifyAuthCode(credential: credential));
      },
      verificationFailed: (FirebaseAuthException exception) async {
        switch (authProcedure) {
          case AuthProcedure.login:
          case AuthProcedure.signup:
            buildContext.read<PhoneAuthBloc>().add(UpdateStatus(
                  BlocStatus.error,
                  error: getFirebaseErrorCodeMessage(exception.code),
                ));
            break;
          case AuthProcedure.deleteAccount:
            buildContext.read<AccountBloc>().add(AccountDeletionCheck(
                  passed: false,
                  error: getFirebaseErrorCodeMessage(exception.code),
                ));
            break;
          case AuthProcedure.anonymousLogin:
          case AuthProcedure.logout:
          case AuthProcedure.none:
            break;
        }

        throw exception;
      },
      codeSent: (String verificationId, int? resendToken) async {
        buildContext
            .read<AuthCodeBloc>()
            .add(UpdateVerificationId(verificationId));

        switch (authProcedure) {
          case AuthProcedure.login:
          case AuthProcedure.signup:
            buildContext
                .read<PhoneAuthBloc>()
                .add(const UpdateStatus(BlocStatus.success));
            break;
          case AuthProcedure.deleteAccount:
            buildContext
                .read<AccountBloc>()
                .add(const AccountDeletionCheck(passed: true));
            break;
          case AuthProcedure.anonymousLogin:
          case AuthProcedure.logout:
          case AuthProcedure.none:
            break;
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) async {
        buildContext
            .read<AuthCodeBloc>()
            .add(UpdateVerificationId(verificationId));

        switch (authProcedure) {
          case AuthProcedure.login:
          case AuthProcedure.signup:
            buildContext
                .read<PhoneAuthBloc>()
                .add(const UpdateStatus(BlocStatus.success));
            break;
          case AuthProcedure.deleteAccount:
            buildContext
                .read<AccountBloc>()
                .add(const AccountDeletionCheck(passed: true));
            break;
          case AuthProcedure.anonymousLogin:
          case AuthProcedure.logout:
          case AuthProcedure.none:
            break;
        }
      },
      timeout: const Duration(seconds: 30),
    );
  }

  static Future<void> sendEmailAuthCode({
    required String emailAddress,
    required BuildContext buildContext,
    required AuthProcedure authProcedure,
  }) async {
    try {
      final emailSignupResponse = await AirqoApiClient()
          .requestEmailVerificationCode(emailAddress, false);

      if (emailSignupResponse == null) {
        switch (authProcedure) {
          case AuthProcedure.login:
          case AuthProcedure.signup:
            buildContext.read<EmailAuthBloc>().add(const EmailValidationFailed(
                  AuthenticationError.authFailure,
                ));
            break;
          case AuthProcedure.deleteAccount:
            buildContext.read<AccountBloc>().add(const AccountDeletionCheck(
                  error: AuthenticationError.authFailure,
                  passed: false,
                ));
            break;
          case AuthProcedure.anonymousLogin:
          case AuthProcedure.logout:
          case AuthProcedure.none:
            break;
        }
      } else {
        buildContext.read<AuthCodeBloc>().add(UpdateEmailCredentials(
              emailVerificationLink: emailSignupResponse.loginLink,
              emailToken: emailSignupResponse.token,
            ));

        switch (authProcedure) {
          case AuthProcedure.login:
          case AuthProcedure.signup:
            buildContext
                .read<EmailAuthBloc>()
                .add(const EmailValidationPassed());
            break;
          case AuthProcedure.deleteAccount:
            buildContext
                .read<AccountBloc>()
                .add(const AccountDeletionCheck(passed: true));
            break;
          case AuthProcedure.anonymousLogin:
          case AuthProcedure.logout:
          case AuthProcedure.none:
            break;
        }
      }
    } catch (exception, stackTrace) {
      buildContext
          .read<EmailAuthBloc>()
          .add(const EmailValidationFailed(AuthenticationError.authFailure));
      await logException(
        exception,
        stackTrace,
      );
    }
  }

  static Future<bool> updateCredentials({
    required AuthMethod authMethod,
    required BuildContext context,
    String? emailAddress,
    PhoneAuthCredential? phoneCredential,
  }) async {
    final hasConnection = await hasNetworkConnection();
    if (!hasConnection) {
      return false;
    }
    try {
      final profile = await Profile.getProfile();
      switch (authMethod) {
        case AuthMethod.phone:
          await FirebaseAuth.instance.currentUser!
              .updatePhoneNumber(phoneCredential!)
              .then(
            (_) {
              profile.update();
            },
          );
          break;
        case AuthMethod.email:
          await FirebaseAuth.instance.currentUser!
              .updateEmail(emailAddress!)
              .then(
            (_) {
              profile.update();
            },
          );
          break;
        case AuthMethod.none:
          break;
      }

      return true;
    } on FirebaseAuthException catch (exception) {
      var error = 'Failed to change credentials. Try again later';
      switch (exception.code) {
        case 'email-already-in-use':
          error = 'Email Address already taken';
          break;
        case 'invalid-email':
          error = 'Invalid email address';
          break;
        case 'credential-already-in-use':
          error = 'Phone number already taken';
          break;
        case 'invalid-verification-id':
          error = 'Failed to change phone number. Try again later';
          break;
        case 'session-expired':
          error = 'Your code has expired. Try again later';
          break;
      }

      showSnackBar(
        context,
        error,
      );
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return false;
  }
}
