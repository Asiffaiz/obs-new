import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfile extends ProfileEvent {
  final Map<String, dynamic> profile;

  const UpdateProfile({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ClearProfileError extends ProfileEvent {
  const ClearProfileError();
}
