import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/repositories/rfq_repository.dart';

part 'rfq_submissions_event.dart';
part 'rfq_submissions_state.dart';

class RfqSubmissionsBloc extends Bloc<RfqSubmissionsEvent, RfqSubmissionsState> {
  final RfqRepository _rfqRepository;

  RfqSubmissionsBloc({required RfqRepository rfqRepository})
      : _rfqRepository = rfqRepository,
        super(const RfqSubmissionsState()) {
    on<LoadRfqSubmissions>(_onLoadRfqSubmissions);
    on<RefreshRfqSubmissions>(_onRefreshRfqSubmissions);
  }

  Future<void> _onLoadRfqSubmissions(
    LoadRfqSubmissions event,
    Emitter<RfqSubmissionsState> emit,
  ) async {
    emit(state.copyWith(status: RfqSubmissionsStatus.loading));

    try {
      final submissions = await _rfqRepository.getRfqSubmissions();
      emit(state.copyWith(
        status: RfqSubmissionsStatus.loaded,
        submissions: submissions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RfqSubmissionsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRfqSubmissions(
    RefreshRfqSubmissions event,
    Emitter<RfqSubmissionsState> emit,
  ) async {
    try {
      final submissions = await _rfqRepository.getRfqSubmissions();
      emit(state.copyWith(
        status: RfqSubmissionsStatus.loaded,
        submissions: submissions,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RfqSubmissionsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}

