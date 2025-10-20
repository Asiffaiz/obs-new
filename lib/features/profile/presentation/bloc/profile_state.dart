import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, loading, loaded, error, updating, updated }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? profile;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.errorMessage,
    this.profile ,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? errorMessage,
    Map<String, dynamic>? profile,
  }) {
    return ProfileState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, profile];
}
