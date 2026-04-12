import 'package:agricola_core/agricola_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web-specific implementation of [AuthRepository] using Firebase Auth Web SDK.
class WebAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;

  final GoogleSignIn _googleSignIn;
  WebAuthRepository({fb.FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.idTokenChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUser(firebaseUser);
    });
  }

  @override
  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<Either<AuthFailure, void>> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> markProfileSetupAsSkipped() async {
    return const Right(null);
  }

  @override
  Future<Either<AuthFailure, UserModel>> refreshUserData() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(
          AuthFailure(
            message: 'No user signed in',
            type: AuthFailureType.userNotFound,
          ),
        );
      }
      return Right(_mapFirebaseUser(user));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, String>> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return Right(result.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, UserModel>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(_mapFirebaseUser(result.user!));
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, UserModel>> signInWithGoogle({
    required UserType userType,
    MerchantType? merchantType,
  }) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(
          AuthFailure(
            message: 'Google sign-in cancelled',
            type: AuthFailureType.unknown,
          ),
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return Right(_mapFirebaseUser(result.user!, userType: userType));
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, UserModel>> signUpWithEmailPassword({
    required String email,
    required String password,
    required UserType userType,
    MerchantType? merchantType,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(_mapFirebaseUser(result.user!, userType: userType));
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } catch (e) {
      return Left(AuthFailure.fromException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> updateProfileCompletionStatus(
    bool isComplete,
  ) async {
    // Profile completion is tracked on the backend, not Firebase directly.
    return const Right(null);
  }

  AuthFailure _mapFirebaseError(fb.FirebaseAuthException e) {
    final type = switch (e.code) {
      'user-not-found' => AuthFailureType.userNotFound,
      'wrong-password' => AuthFailureType.wrongPassword,
      'email-already-in-use' => AuthFailureType.emailAlreadyInUse,
      'invalid-email' => AuthFailureType.invalidEmail,
      'weak-password' => AuthFailureType.weakPassword,
      'operation-not-allowed' => AuthFailureType.operationNotAllowed,
      'user-disabled' => AuthFailureType.userDisabled,
      'too-many-requests' => AuthFailureType.tooManyRequests,
      'network-request-failed' => AuthFailureType.networkError,
      'account-exists-with-different-credential' =>
        AuthFailureType.accountExistsWithDifferentCredential,
      'invalid-credential' => AuthFailureType.invalidCredential,
      _ => AuthFailureType.unknown,
    };
    return AuthFailure(message: e.message ?? e.code, type: type);
  }

  // -- Helpers --

  UserModel _mapFirebaseUser(
    fb.User firebaseUser, {
    UserType userType = UserType.merchant,
  }) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber,
      emailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastSignInAt: firebaseUser.metadata.lastSignInTime,
      userType: userType,
      isAnonymous: firebaseUser.isAnonymous,
    );
  }
}
