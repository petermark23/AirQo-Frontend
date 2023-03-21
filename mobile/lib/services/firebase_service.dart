import 'dart:io';

import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/cupertino.dart';

class CloudAnalytics {
  static Future<bool> logEvent(CloudAnalyticsEvent analyticsEvent) async {
    await FirebaseAnalytics.instance.logEvent(
      name: analyticsEvent.snakeCase(),
    );

    return true;
  }

  static Future<void> logAppRating() async {
    await CloudAnalytics.logEvent(
      CloudAnalyticsEvent.rateApp,
    );
  }

  static Future<void> logSignUpEvents() async {
    try {
      await Future.wait([
        logEvent(CloudAnalyticsEvent.createUserProfile),
        logNetworkProvider(),
        logPlatformType(),
        logGender(),
      ]);
    } catch (exception, stackTrace) {
      debugPrint('$exception\n$stackTrace');
    }
  }

  static Future<void> logSignOutEvents() async {
    try {
      await Future.wait([]);
    } catch (exception, stackTrace) {
      debugPrint('$exception\n$stackTrace');
    }
  }

  static Future<void> logSignInEvents() async {
    try {
      await Future.wait([
        logPlatformType(),
      ]);
    } catch (exception, stackTrace) {
      debugPrint('$exception\n$stackTrace');
    }
  }

  static Future<void> logAirQualitySharing() async {
    // TODO implement
    // final profile = Hive.box<Profile>(HiveBox.profile).getAt(0);
    // if (profile != null) {
    //   if (profile.aqShares >= 5) {
    //     await CloudAnalytics.logEvent(
    //       CloudAnalyticsEvent.shareAirQualityInformation,
    //     );
    //   }
    // }
  }

  static Future<void> logNetworkProvider() async {
    // TODO implement
    // final profile = Hive.box<Profile>(HiveBox.profile).getAt(0);
    // if (profile != null) {
    //   final carrier = await AirqoApiClient().getCarrier(profile.phoneNumber);
    //   if (carrier.toLowerCase().contains('airtel')) {
    //     await logEvent(CloudAnalyticsEvent.airtelUser);
    //   } else if (carrier.toLowerCase().contains('mtn')) {
    //     await logEvent(CloudAnalyticsEvent.mtnUser);
    //   } else {
    //     await logEvent(
    //       CloudAnalyticsEvent.otherNetwork,
    //     );
    //   }
    // }
  }

  static Future<void> logPlatformType() async {
    if (Platform.isAndroid) {
      await logEvent(
        CloudAnalyticsEvent.androidUser,
      );
    } else if (Platform.isIOS) {
      await logEvent(
        CloudAnalyticsEvent.iosUser,
      );
    } else {
      debugPrint('Unknown Platform');
    }
  }

  static Future<void> logGender() async {
    // TODO implement
    // final profile = Hive.box<Profile>(HiveBox.profile).getAt(0);
    // if (profile != null) {
    //   if (profile.gender() == Gender.male) {
    //     await logEvent(
    //       CloudAnalyticsEvent.maleUser,
    //     );
    //   } else if (profile.gender() == Gender.female) {
    //     await logEvent(
    //       CloudAnalyticsEvent.femaleUser,
    //     );
    //   } else {
    //     await logEvent(
    //       CloudAnalyticsEvent.undefinedGender,
    //     );
    //   }
    // }
  }
}

class CloudStore {
  static Future<bool> updateKya(List<Kya> kyaList) async {
    final batch = FirebaseFirestore.instance.batch();

    final userId = CustomAuth.getUserId();
    if (userId.isEmpty) {
      return false;
    }

    try {
      for (final kya in kyaList) {
        KyaProgress progress = KyaProgress.fromKya(kya);
        final document = FirebaseFirestore.instance
            .collection(Config.usersKyaCollection)
            .doc(userId)
            .collection(userId)
            .doc(progress.id);
        batch.set(
          document,
          progress.toJson(),
        );
      }
      batch.commit();
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );

      return false;
    }

    return true;
  }

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
    if (userId.isEmpty) {
      return kya;
    }

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
    if (userId.isEmpty) {
      return [];
    }

    try {
      final notificationsJson = await FirebaseFirestore.instance
          .collection(Config.usersNotificationCollection)
          .doc(userId)
          .collection(userId)
          .get();

      final notifications = <AppNotification>[];

      for (final doc in notificationsJson.docs) {
        try {
          notifications.add(AppNotification.fromJson(
            doc.data(),
          ));
        } catch (e) {
          debugPrint(e.toString());
        }
      }

      return notifications;
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return [];
  }

  static Future<List<LocationHistory>> getLocationHistory() async {
    final uid = CustomAuth.getUserId();
    if (uid.isEmpty) {
      return [];
    }

    try {
      final locationHistoryCollection = await FirebaseFirestore.instance
          .collection(Config.usersLocationHistoryCollection)
          .doc(uid)
          .collection(uid)
          .get();

      final locationHistory = <LocationHistory>[];

      for (final doc in locationHistoryCollection.docs) {
        final history = LocationHistory.parseAnalytics(
          doc.data(),
        );
        if (history != null) {
          locationHistory.add(history);
        }
      }

      return locationHistory;
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return [];
  }

  static Future<bool> updateLocationHistory(
    List<LocationHistory> historyList,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final userId = CustomAuth.getUserId();
    if (userId.isEmpty) {
      return false;
    }

    try {
      for (final history in historyList) {
        final document = FirebaseFirestore.instance
            .collection(Config.usersLocationHistoryCollection)
            .doc(userId)
            .collection(userId)
            .doc(history.placeId);
        batch.set(
          document,
          history.toJson(),
        );
      }
      batch.commit();
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );

      return false;
    }

    return true;
  }

  static Future<Profile?> getProfile() async {
    try {
      final userId = CustomAuth.getUserId();
      if (userId.isEmpty) {
        return null;
      }

      final userJson = await FirebaseFirestore.instance
          .collection(Config.usersCollection)
          .doc(userId)
          .get();

      return Profile.fromJson(
        userJson.data()!,
      );
    } on FirebaseException catch (_) {
      return null;
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return null;
  }

  static Future<List<FavouritePlace>> getFavouritePlaces() async {
    try {
      final userId = CustomAuth.getUserId();

      if (userId.isEmpty) return [];

      final jsonObject = await FirebaseFirestore.instance
          .collection(Config.favPlacesCollection)
          .doc(userId)
          .collection(userId)
          .get();

      final favouritePlaces = <FavouritePlace>[];

      for (final doc in jsonObject.docs) {
        try {
          favouritePlaces.add(FavouritePlace.fromFirestore(snapshot: doc));
        } catch (exception, stackTrace) {
          await logException(exception, stackTrace);
        }
      }

      return favouritePlaces;
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );

      return [];
    }
  }

  static Future<bool> updateFavouritePlaces(
    List<FavouritePlace> favouritePlaces,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final userId = CustomAuth.getUserId();
    if (userId.isEmpty) {
      return false;
    }

    try {
      for (final favouritePlace in favouritePlaces) {
        final document = FirebaseFirestore.instance
            .collection(Config.favPlacesCollection)
            .doc(userId)
            .collection(userId)
            .doc(favouritePlace.placeId);
        batch.set(
          document,
          favouritePlace.toJson(),
        );
      }
      batch.commit();
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );

      return false;
    }

    return true;
  }

  static Future<bool> updateProfile(Profile profile) async {
    final User? currentUser = CustomAuth.getUser();
    if (!profile.isSignedIn || currentUser == null) {
      return false;
    }

    try {
      await Future.wait([
        currentUser.updateDisplayName(profile.firstName),
        FirebaseFirestore.instance
            .collection(Config.usersCollection)
            .doc(currentUser.uid)
            .set(profile.toJson()),
      ]);
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );

      return false;
    }

    return true;
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
  static Future<bool> guestSignIn() async {
    UserCredential userCredential;
    User? user = getUser();
    if (user != null && user.isAnonymous) {
      return true;
    }

    userCredential = await FirebaseAuth.instance.signInAnonymously();

    return userCredential.user != null;
  }

  static Future<bool> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      return true;
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );

      return false;
    }
  }

  static Future<bool> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return true;
  }

  static Future<bool> firebaseSignIn(
    AuthCredential? authCredential,
  ) async {
    final UserCredential userCredential = authCredential == null
        ? await FirebaseAuth.instance.signInAnonymously()
        : await FirebaseAuth.instance.signInWithCredential(authCredential);

    return userCredential.user != null;
  }

  static User? getUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static String getUserId() {
    if (!isLoggedIn()) {
      return '';
    }

    return getUser()!.uid;
  }

  static bool isLoggedIn() {
    final user = getUser();
    if (user == null) {
      return false;
    }

    return !user.isAnonymous;
  }

  static Future<bool> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (exception, stackTrace) {
      await logException(
        exception,
        stackTrace,
      );
    }

    return true;
  }

  static Future<bool> reAuthenticate(AuthCredential authCredential) async {
    final userCredential = await FirebaseAuth.instance.currentUser!
        .reauthenticateWithCredential(authCredential);

    return userCredential.user != null;
  }

  static FirebaseAuthError getFirebaseErrorCodeMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return FirebaseAuthError.invalidEmailAddress;
      case 'email-already-in-use':
        return FirebaseAuthError.emailTaken;
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return FirebaseAuthError.accountTaken;
      case 'invalid-verification-code':
        return FirebaseAuthError.invalidAuthCode;
      case 'invalid-phone-number':
        return FirebaseAuthError.invalidPhoneNumber;
      case 'session-expired':
      case 'expired-action-code':
        return FirebaseAuthError.authSessionTimeout;
      case 'user-disabled':
      case 'user-mismatch':
      case 'user-not-found':
        return FirebaseAuthError.accountInvalid;
      case 'requires-recent-login':
        return FirebaseAuthError.logInRequired;
      case 'invalid-verification-id':
      case 'invalid-credential':
      case 'missing-client-identifier':
      default:
        return FirebaseAuthError.authFailure;
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
        // switch (authProcedure) {
        //   case AuthProcedure.login:
        //   case AuthProcedure.signup:
        //     buildContext
        //         .read<PhoneAuthBloc>()
        //         .add(const UpdateStatus(BlocStatus.success));
        //     break;
        //   case AuthProcedure.deleteAccount:
        //     buildContext
        //         .read<AccountBloc>()
        //         .add(const AccountDeletionCheck(passed: true));
        //     break;
        //   case AuthProcedure.anonymousLogin:
        //   case AuthProcedure.logout:
        //   case AuthProcedure.none:
        //     break;
        // }
        //
        // buildContext
        //     .read<AuthCodeBloc>()
        //     .add(VerifyAuthCode(credential: credential));
      },
      verificationFailed: (FirebaseAuthException exception) async {
        // switch (authProcedure) {
        //   case AuthProcedure.login:
        //   case AuthProcedure.signup:
        //     buildContext.read<PhoneAuthBloc>().add(UpdateStatus(
        //           BlocStatus.error,
        //           error: getFirebaseErrorCodeMessage(exception.code),
        //         ));
        //     break;
        //   case AuthProcedure.deleteAccount:
        //     buildContext.read<AccountBloc>().add(AccountDeletionCheck(
        //           passed: false,
        //           error: getFirebaseErrorCodeMessage(exception.code),
        //         ));
        //     break;
        //   case AuthProcedure.anonymousLogin:
        //   case AuthProcedure.logout:
        //   case AuthProcedure.none:
        //     break;
        // }
        //
        // throw exception;
      },
      codeSent: (String verificationId, int? resendToken) {
        // buildContext
        //     .read<AuthCodeBloc>()
        //     .add(UpdateVerificationId(verificationId));
        //
        // switch (authProcedure) {
        //   case AuthProcedure.login:
        //   case AuthProcedure.signup:
        //     buildContext
        //         .read<PhoneAuthBloc>()
        //         .add(const UpdateStatus(BlocStatus.success));
        //     break;
        //   case AuthProcedure.deleteAccount:
        //     // buildContext
        //     //     .read<AccountBloc>()
        //     //     .add(const AccountDeletionCheck(passed: true));
        //     break;
        //   case AuthProcedure.anonymousLogin:
        //   case AuthProcedure.logout:
        //   case AuthProcedure.none:
        //     break;
        // }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // buildContext
        //     .read<AuthCodeBloc>()
        //     .add(UpdateVerificationId(verificationId));
        //
        // switch (authProcedure) {
        //   case AuthProcedure.login:
        //   case AuthProcedure.signup:
        //     buildContext
        //         .read<PhoneAuthBloc>()
        //         .add(const UpdateStatus(BlocStatus.success));
        //     break;
        //   case AuthProcedure.deleteAccount:
        //     // buildContext
        //     //     .read<AccountBloc>()
        //     //     .add(const AccountDeletionCheck(passed: true));
        //     break;
        //   case AuthProcedure.anonymousLogin:
        //   case AuthProcedure.logout:
        //   case AuthProcedure.none:
        //     break;
        // }
      },
      timeout: const Duration(seconds: 30),
    );
  }

  static Future<void> sendEmailAuthCode({
    required String emailAddress,
    required BuildContext buildContext,
    required AuthProcedure authProcedure,
  }) async {
    // try {
    //   final emailSignupResponse = await AirqoApiClient()
    //       .requestEmailVerificationCode(emailAddress, false);
    //
    //   if (emailSignupResponse == null) {
    //     switch (authProcedure) {
    //       case AuthProcedure.login:
    //       case AuthProcedure.signup:
    //         buildContext.read<EmailAuthBloc>().add(const EmailValidationFailed(
    //               AuthenticationError.authFailure,
    //             ));
    //         break;
    //       case AuthProcedure.deleteAccount:
    //         // buildContext.read<AccountBloc>().add(const AccountDeletionCheck(
    //         //       error: AuthenticationError.authFailure,
    //         //       passed: false,
    //         //     ));
    //         break;
    //       case AuthProcedure.anonymousLogin:
    //       case AuthProcedure.logout:
    //       case AuthProcedure.none:
    //         break;
    //     }
    //   } else {
    //     buildContext.read<AuthCodeBloc>().add(UpdateEmailCredentials(
    //           emailVerificationLink: emailSignupResponse.loginLink,
    //           emailToken: emailSignupResponse.token,
    //         ));
    //
    //     switch (authProcedure) {
    //       case AuthProcedure.login:
    //       case AuthProcedure.signup:
    //         buildContext
    //             .read<EmailAuthBloc>()
    //             .add(const EmailValidationPassed());
    //         break;
    //       case AuthProcedure.deleteAccount:
    //         // buildContext
    //         //     .read<AccountBloc>()
    //         //     .add(const AccountDeletionCheck(passed: true));
    //         break;
    //       case AuthProcedure.anonymousLogin:
    //       case AuthProcedure.logout:
    //       case AuthProcedure.none:
    //         break;
    //     }
    //   }
    // } catch (exception, stackTrace) {
    //   buildContext
    //       .read<EmailAuthBloc>()
    //       .add(const EmailValidationFailed(AuthenticationError.authFailure));
    //   await logException(
    //     exception,
    //     stackTrace,
    //   );
    // }
  }
}
