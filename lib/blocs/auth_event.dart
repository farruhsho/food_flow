// lib/blocs/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

// 1. Check auth status
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

// 2. Login
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

// 3. Register
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String role;
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.role,
  });
  @override
  List<Object?> get props => [email, password, name, phone, role];
}

// 4. Google Sign-In
class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

// 5. Sign Out
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

// 6. Password Reset
class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

// 7. Update Profile
class UpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? phone;
  final String? photo;
  const UpdateProfileRequested({this.name, this.phone, this.photo});
  @override
  List<Object?> get props => [name, phone, photo];
}

// YANGI: SignInEvent va SignUpEvent (LoginScreen va RegisterScreen uchun)
class SignInEvent extends AuthEvent {
  final String email;
  final String password;
  const SignInEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String role;
  const SignUpEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
  });
  @override
  List<Object?> get props => [email, password, fullName, phone, role];
}