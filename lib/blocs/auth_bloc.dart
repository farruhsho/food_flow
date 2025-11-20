import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/auth_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthStorageService _authStorage = AuthStorageService();

  AuthBloc() : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      // First check if user is logged in via Firebase Auth
      var user = _firebaseAuth.currentUser;

      // If not logged in with Firebase, check saved credentials
      if (user == null) {
        final isLoggedIn = await _authStorage.isLoggedIn();
        if (isLoggedIn) {
          final savedData = await _authStorage.getSavedUserData();
          if (savedData != null) {
            // Try to fetch user data from Firestore using saved userId
            final userDoc = await _firestore
                .collection('users')
                .doc(savedData['userId'])
                .get();

            if (userDoc.exists) {
              final userData = User.fromFirestore(
                userDoc.data()!,
                savedData['userId'],
              );
              emit(AuthAuthenticated(user: userData));
              return;
            }
          }
        }
        emit(const AuthUnauthenticated());
        return;
      }

      // User is logged in with Firebase, get their data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = User.fromFirestore(userDoc.data()!, user.uid);
        // Save user data for auto-login
        await _authStorage.saveUserData(
          userId: userData.id,
          email: userData.email,
          role: userData.role,
          rememberMe: true,
        );
        emit(AuthAuthenticated(user: userData));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Xato: $e'));
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = User.fromFirestore(
          userDoc.data()!,
          userCredential.user!.uid,
        );

        // Save user data for auto-login
        await _authStorage.saveUserData(
          userId: userData.id,
          email: userData.email,
          role: userData.role,
          rememberMe: true,
        );

        emit(AuthAuthenticated(user: userData));
      } else {
        emit(const AuthError(message: 'Foydalanuvchi topilmadi'));
      }
    } on auth.FirebaseAuthException catch (e) {
      String message = 'Kirish xatosi';
      if (e.code == 'user-not-found') {
        message = 'Foydalanuvchi topilmadi';
      } else if (e.code == 'wrong-password') {
        message = 'Noto\'g\'ri parol';
      } else if (e.code == 'invalid-email') {
        message = 'Noto\'g\'ri email formati';
      } else if (e.code == 'user-disabled') {
        message = 'Foydalanuvchi bloklangan';
      }
      emit(AuthError(message: message));
    } catch (e) {
      emit(AuthError(message: 'Kirish xatosi: $e'));
    }
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      // Check if email already exists
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(event.email);
      if (methods.isNotEmpty) {
        emit(const AuthError(message: 'Bu email allaqachon ro\'yxatdan o\'tgan'));
        return;
      }

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final userData = User(
        id: userCredential.user!.uid,
        email: event.email,
        role: event.role,
        name: event.name,
        phone: event.phone,
        points: 0,
        discounts: 0,
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData.toFirestore());

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user data for auto-login
      await _authStorage.saveUserData(
        userId: userData.id,
        email: userData.email,
        role: userData.role,
        rememberMe: true,
      );

      emit(AuthAuthenticated(user: userData));
    } on auth.FirebaseAuthException catch (e) {
      String message = 'Ro\'yxatdan o\'tish xatosi';
      if (e.code == 'weak-password') {
        message = 'Parol juda zaif';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu email allaqachon ishlatilmoqda';
      } else if (e.code == 'invalid-email') {
        message = 'Noto\'g\'ri email formati';
      }
      emit(AuthError(message: message));
    } catch (e) {
      emit(AuthError(message: 'Ro\'yxatdan o\'tish xatosi: $e'));
    }
  }

  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Check if user document exists
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      User userData;
      if (userDoc.exists) {
        userData = User.fromFirestore(userDoc.data()!, userCredential.user!.uid);
      } else {
        // Create new user document
        userData = User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          role: 'client',
          name: userCredential.user!.displayName ?? 'Foydalanuvchi',
          photo: userCredential.user!.photoURL,
          points: 0,
          discounts: 0,
          isActive: true,
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData.toFirestore());
      }

      // Save user data for auto-login
      await _authStorage.saveUserData(
        userId: userData.id,
        email: userData.email,
        role: userData.role,
        rememberMe: true,
      );

      emit(AuthAuthenticated(user: userData));
    } catch (e) {
      emit(AuthError(message: 'Google orqali kirish xatosi: $e'));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      // Clear saved user data
      await _authStorage.clearUserData();

      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Chiqish xatosi: $e'));
    }
  }

  Future<void> _onPasswordResetRequested(
      PasswordResetRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: event.email);
      emit(const PasswordResetEmailSent());
      // Return to unauthenticated after showing message
      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthUnauthenticated());
    } on auth.FirebaseAuthException catch (e) {
      String message = 'Parolni tiklash xatosi';
      if (e.code == 'user-not-found') {
        message = 'Foydalanuvchi topilmadi';
      } else if (e.code == 'invalid-email') {
        message = 'Noto\'g\'ri email formati';
      }
      emit(AuthError(message: message));
    } catch (e) {
      emit(AuthError(message: 'Parolni tiklash xatosi: $e'));
    }
  }

  Future<void> _onUpdateProfileRequested(
      UpdateProfileRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(const AuthError(message: 'Foydalanuvchi topilmadi'));
        return;
      }

      final updateData = <String, dynamic>{};
      if (event.name != null) updateData['name'] = event.name;
      if (event.phone != null) updateData['phone'] = event.phone;
      if (event.photo != null) updateData['photo'] = event.photo;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update(updateData);

        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final userData = User.fromFirestore(userDoc.data()!, currentUser.uid);
        emit(AuthAuthenticated(user: userData));
      }
    } catch (e) {
      emit(AuthError(message: 'Profilni yangilash xatosi: $e'));
    }
  }
}