import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';

class UserState {
  final String name;
  const UserState({required this.name});

  UserState copyWith({String? name}) => UserState(
        name: name ?? this.name,
      );
}

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(const UserState(name: ""));

  Future<void> loadUser() async {
    final user = await GetIt.I<AuthService>().getUserData();
    emit(UserState(name: user['name'] ?? ''));
  }

  void updateName(String newName) {
    emit(state.copyWith(name: newName));
  }
}