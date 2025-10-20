import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/agreements_repository.dart';
import '../../domain/models/agreement_model.dart';
import 'agreements_event.dart';
import 'agreements_state.dart';

class AgreementsBloc extends Bloc<AgreementsEvent, AgreementsState> {
  final AgreementsRepository _agreementsRepository;

  AgreementsBloc({required AgreementsRepository agreementsRepository})
    : _agreementsRepository = agreementsRepository,
      super(const AgreementsState()) {
    on<LoadAgreements>(_onLoadAgreements);
    // on<SignAgreement>(_onSignAgreement);
    on<NextAgreement>(_onNextAgreement);
    on<PreviousAgreement>(_onPreviousAgreement);
    on<GoToAgreement>(_onGoToAgreement);
    on<CheckMandatoryAgreements>(_onCheckMandatoryAgreements);
    on<SendToSignee>(_onSendToSignee);
    on<AcceptAgreement>(_onAcceptAgreement);
    on<SaveSignature>(_onSaveSignature);
    on<SaveOptionalSignature>(_onSaveOptionalSignature);
    on<LoadSignedAgreements>(_onLoadSignedAgreements);
    on<LoadArchivedAgreements>(_onLoadArchivedAgreements);
    on<LoadOptionalAgreements>(_onLoadOptionalAgreements);
  }

  Future<void> _onLoadAgreements(
    LoadAgreements event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AgreementsStatus.loading));

      final agreements = await _agreementsRepository.getMandatoryAgreements();
      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();

      emit(
        state.copyWith(
          status: AgreementsStatus.loaded,
          agreements: agreements,
          allMandatoryAgreementsSigned: allSigned,
          viewMode: AgreementViewMode.list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Future<void> _onSignAgreement(
  //   SignAgreement event,
  //   Emitter<AgreementsState> emit,
  // ) async {
  //   try {
  //     emit(state.copyWith(status: AgreementsStatus.signing));

  //     final signedAgreement = await _agreementsRepository.signAgreement(
  //       event.agreementId,
  //       event.signature,
  //       event.signMethod,
  //       event.payload,
  //     );

  //     final updatedAgreements = List.of(state.agreements);
  //     final index = updatedAgreements.indexWhere(
  //       (a) => a.id == event.agreementId,
  //     );

  //     if (index != -1) {
  //       updatedAgreements[index] = signedAgreement;
  //     }

  //     final allSigned =
  //         await _agreementsRepository.areAllMandatoryAgreementsSigned();

  //     emit(
  //       state.copyWith(
  //         status: AgreementsStatus.signed,
  //         agreements: updatedAgreements,
  //         allMandatoryAgreementsSigned: allSigned,
  //         viewMode: AgreementViewMode.detail,
  //       ),
  //     );
  //   } catch (e) {
  //     emit(
  //       state.copyWith(
  //         status: AgreementsStatus.error,
  //         errorMessage: e.toString(),
  //       ),
  //     );
  //   }
  // }

  void _onNextAgreement(NextAgreement event, Emitter<AgreementsState> emit) {
    // if (state.hasNextAgreement) {
    //   emit(
    //     state.copyWith(currentAgreementIndex: state.currentAgreementIndex + 1),
    //   );
    // }
    emit(state.copyWith(status: AgreementsStatus.showNextAgreement));
  }

  void _onPreviousAgreement(
    PreviousAgreement event,
    Emitter<AgreementsState> emit,
  ) {
    if (state.hasPreviousAgreement) {
      emit(
        state.copyWith(currentAgreementIndex: state.currentAgreementIndex - 1),
      );
    }
  }

  void _onGoToAgreement(GoToAgreement event, Emitter<AgreementsState> emit) {
    if (event.index >= 0 && event.index < state.agreements.length) {
      emit(
        state.copyWith(
          currentAgreementIndex: event.index,
          viewMode: AgreementViewMode.detail,
        ),
      );
    }
  }

  Future<void> _onCheckMandatoryAgreements(
    CheckMandatoryAgreements event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();

      emit(state.copyWith(allMandatoryAgreementsSigned: allSigned));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSendToSignee(
    SendToSignee event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AgreementsStatus.sendingToSignee));

      final success = await _agreementsRepository.sendToSignee(
        event.agreementId,
        event.name,
        event.email,
        event.title,
        event.message,
      );

      if (success) {
        emit(
          state.copyWith(
            status: AgreementsStatus.sentToSignee,
            viewMode: AgreementViewMode.detail,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AgreementsStatus.error,
            errorMessage: 'Failed to send agreement to signee',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAcceptAgreement(
    AcceptAgreement event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AgreementsStatus.acceptingAgreement));

      final acceptedAgreement = await _agreementsRepository.acceptAgreement(
        event.agreementId,
      );

      final updatedAgreements = List.of(state.agreements);
      final index = updatedAgreements.indexWhere(
        (a) => a.id == event.agreementId,
      );

      if (index != -1) {
        updatedAgreements[index] = acceptedAgreement;
      }

      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();

      emit(
        state.copyWith(
          status: AgreementsStatus.acceptedAgreement,
          agreements: updatedAgreements,
          allMandatoryAgreementsSigned: allSigned,
          viewMode: AgreementViewMode.detail,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.savingSignatureError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveSignature(
    SaveSignature event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: AgreementsStatus.savingSignature,
          signatureUrl: event.signatureUrl,
        ),
      );

      // Use the payload for the API call if provided
      bool success = false;
      if (event.payload != null) {
        // Call the real API endpoint
        final isSignedAgreement = await _agreementsRepository.signAgreement(
          event.agreementId,
          event.signatureUrl,
          event.signMethod,
          event.payload,
        );
        success = isSignedAgreement;
      } else {
        // Fall back to the mock implementation
        await Future.delayed(const Duration(milliseconds: 800));
        success = true;
      }

      if (!success) {
        print('Failed to save signature');
        throw Exception('Failed to save signature');
      }

      // Check if all mandatory agreements are signed
      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();

      emit(
        state.copyWith(
          status: AgreementsStatus.savedSignature,

          allMandatoryAgreementsSigned: allSigned,
          viewMode: AgreementViewMode.detail,
        ),
      );
    } catch (e) {
      print(e);
      emit(
        state.copyWith(
          status: AgreementsStatus.savingSignatureError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveOptionalSignature(
    SaveOptionalSignature event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: AgreementsStatus.savingSignature,
          signatureUrl: event.signatureUrl,
        ),
      );

      // Use the payload for the API call if provided
      //commenting for test

      bool success = false;
      if (event.payload != null) {
        // Call the real API endpoint
        final isSignedAgreement = await _agreementsRepository.signAgreement(
          event.agreementId,
          event.signatureUrl,
          event.signMethod,
          event.payload,
        );
        success = isSignedAgreement;
      } else {
        // Fall back to the mock implementation
        await Future.delayed(const Duration(milliseconds: 800));
        // success = true;
      }

      if (!success) {
        throw Exception('Failed to save signature');
      }

      // Mark the specific agreement as signed
      // final updatedAgreements = List.of(state.agreements);
      // final index = updatedAgreements.indexWhere(
      //   (a) => a.id.toString() == event.agreementId,
      // );

      // if (index != -1) {
      //   updatedAgreements[index] = updatedAgreements[index].copyWith(
      //     status: AgreementStatus.signed,
      //     signedDate: DateTime.now(),
      //     signatureUrl: event.signatureUrl,
      //   );
      // }

      print("object");
      emit(
        state.copyWith(
          status: AgreementsStatus.savedSignature,
          // agreements: updatedAgreements,
          allMandatoryAgreementsSigned: false,
          viewMode: AgreementViewMode.detail,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.savingSignatureError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadSignedAgreements(
    LoadSignedAgreements event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AgreementsStatus.loadingSignedAgreements));

      final signedAgreements =
          await _agreementsRepository.getSignedAgreements();

      emit(
        state.copyWith(
          status: AgreementsStatus.loadedSignedAgreements,
          signedAgreements: signedAgreements,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadArchivedAgreements(
    LoadArchivedAgreements event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AgreementsStatus.loadingArchivedAgreements));

      final archivedAgreements =
          await _agreementsRepository.getArchivedAgreements();

      emit(
        state.copyWith(
          status: AgreementsStatus.loadedArchivedAgreements,
          archivedAgreements: archivedAgreements,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadOptionalAgreements(
    LoadOptionalAgreements event,
    Emitter<AgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AgreementsStatus.loadingOptionalAgreements));

      final agreements = await _agreementsRepository.getOptionalAgreements();

      emit(
        state.copyWith(
          status: AgreementsStatus.loadedOptionalAgreements,
          agreements: agreements,
          viewMode: AgreementViewMode.list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgreementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
