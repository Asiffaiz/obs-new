import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/reports/domain/models/reports_model.dart';
import 'package:voicealerts_obs/features/reports/domain/repositories/reports_repository.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository _reportsRepository;

  ReportsBloc({required ReportsRepository reportsRepository})
    : _reportsRepository = reportsRepository,
      super(ReportsInitial()) {
    on<LoadReportsData>(_onLoadReportsData);
    on<GetReportUrl>(_onGetReportUrl);
  }

  Future<void> _onLoadReportsData(
    LoadReportsData event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      emit(ReportsLoading());

      final reportsData = await _reportsRepository.getReportsData();

      emit(ReportsLoaded(reportsData: reportsData));
    } catch (e) {
      emit(ReportsError(errorMessage: e.toString()));
    }
  }

  Future<void> _onGetReportUrl(
    GetReportUrl event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      final currentReportsData = state.reportsData;
      emit(ReportUrlLoading(reportsData: currentReportsData));

      final urlData = await _reportsRepository.getReportUrl(event.reportId);

      emit(ReportUrlLoaded(
        url: urlData['url'] ?? '',
        title: urlData['title'] ?? '',
        reportsData: currentReportsData,
      ));
    } catch (e) {
      emit(
        ReportUrlError(
          errorMessage: e.toString(),
          reportsData: state.reportsData,
        ),
      );
    }
  }
}
