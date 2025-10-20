import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicealerts_obs/core/services/text_recognition_service.dart';
import 'package:voicealerts_obs/features/auth/domain/repositories/auth_repository.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/repositories/business_card_repository.dart';

import 'business_card_event.dart';
import 'business_card_state.dart';

class BusinessCardBloc extends Bloc<BusinessCardEvent, BusinessCardState> {
  final BusinessCardRepository _repository;
  final TextRecognitionService _textRecognitionService;
  final AuthRepository _authRepository;
  BusinessCardBloc({
    required BusinessCardRepository repository,
    required TextRecognitionService textRecognitionService,
    required AuthRepository authRepository,
  }) : _repository = repository,
       _textRecognitionService = textRecognitionService,
       _authRepository = authRepository,

       super(BusinessCardInitial()) {
    on<LoadBusinessCards>(_onLoadBusinessCards);
    on<LoadBusinessCardDetails>(_onLoadBusinessCardDetails);
    on<SaveBusinessCard>(_onSaveBusinessCard);

    //////////
    on<SignInWithBusinessCardRequested>(_onSignInWithBusinessCardRequested);
    on<CheckBusinessCardUserExistsRequested>(
      _onCheckBusinessCardUserExistsRequested,
    );
    on<FillRegistrationWithBusinessCardData>(
      _onFillRegistrationWithBusinessCardData,
    );
  }

  Future<void> _onLoadBusinessCards(
    LoadBusinessCards event,
    Emitter<BusinessCardState> emit,
  ) async {
    emit(BusinessCardLoading());
    final result = await _repository.getAllBusinessCards();

    result.fold(
      (error) => emit(BusinessCardError(error)),
      (cards) => emit(BusinessCardsLoaded(cards)),
    );
  }

  Future<void> _onLoadBusinessCardDetails(
    LoadBusinessCardDetails event,
    Emitter<BusinessCardState> emit,
  ) async {
    emit(BusinessCardLoading());
    final result = await _repository.getBusinessCard(event.cardId);

    result.fold((error) => emit(BusinessCardError(error)), (card) {
      if (card != null) {
        emit(BusinessCardDetailLoaded(card));
      } else {
        emit(BusinessCardError('Business card not found'));
      }
    });
  }

  Future<void> _onSaveBusinessCard(
    SaveBusinessCard event,
    Emitter<BusinessCardState> emit,
  ) async {
    emit(BusinessCardLoading());
    try {
      // Extract business card info from image
      //////////
      final BusinessCard businessCard = await _textRecognitionService
          .extractBusinessCardInfo(
            event.imagePath,
            useLocalProcessing: event.useLocalProcessing,
          );

      // Log the extracted data for debugging
      print('Extracted business card data: ${businessCard.toMap()}');
      emit(BusinessCardDetailLoaded(businessCard));
      ///////////
      // var businessCard = BusinessCard(
      //   id: 1,
      //   name: "Asif Faiz",
      //   company: "NoveltySoft",
      //   email: "asiffaiz@gmail.com",
      //   phoneNumber: "1234567890",
      //   jobTitle: "Software Engineer",
      //   address: "123 Main St, Anytown, USA",
      //   website: "https://www.noveltysoft.com",
      // );
      // emit(BusinessCardDetailLoaded(businessCard));
    } catch (e) {
      print('Exception in _onSaveBusinessCard: ${e.toString()}');
      emit(BusinessCardError('Failed to process image: ${e.toString()}'));
    }
  }

  Future<void> _onSignInWithBusinessCardRequested(
    SignInWithBusinessCardRequested event,
    Emitter<BusinessCardState> emit,
  ) async {
    emit(BusinessCardSigninRequestedLoading());

    try {
      // We have user data from Business Card, now check if this user exists in our API
      add(
        CheckBusinessCardUserExistsRequested(
          businessCardUser: event.businessCardUser,
          email: event.email,
        ),
      );
    } catch (e) {
      emit(BusinessCardSigninRequestedError(e.toString()));
    }
  }

  Future<void> _onCheckBusinessCardUserExistsRequested(
    CheckBusinessCardUserExistsRequested event,
    Emitter<BusinessCardState> emit,
  ) async {
    // Don't change status to loading again since we're already in loading state

    try {
      // Check if user exists in our API
      final userExists = await _authRepository.checkUserExists(event.email, '');

      // if (userExists) {
      if (false) {
        // If user exists, login with API
        final userData = await _authRepository.getUserDataByEmail(event.email);
        emit(BusinessCardUserExists(userData));
      } else {
        // Use the Google user data we already have in state
        if (event.businessCardUser != null) {
          // If user doesn't exist, fill registration form with Google data
          add(
            FillRegistrationWithBusinessCardData(
              email: event.email,
              name: event.businessCardUser!.name ?? '',
              photoUrl: '',
              companyName: event.businessCardUser!.company ?? '',
            ),
          );
          // add(
          //   FillRegistrationWithBusinessCardData(
          //     email: "asiffaiz@gmail.com",
          //     name: "Asif Faiz",
          //     photoUrl: '',
          //     companyName: "NoveltySoft",
          //   ),
          // );
        } else {
          // Handle error if we somehow lost the user data
          emit(
            BusinessCardSigninRequestedError('Failed to get Google user data'),
          );
        }
      }
    } catch (e) {
      emit(BusinessCardSigninRequestedError(e.toString()));
    }
  }

  void _onFillRegistrationWithBusinessCardData(
    FillRegistrationWithBusinessCardData event,
    Emitter<BusinessCardState> emit,
  ) {
    // Split the name into first and last name
    final nameParts = event.name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Emit state with Google user data ready to be filled in registration form
    emit(
      BusinessCardSigninRequestedSuccess(
        additionalData: {
          'email': event.email,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': "$firstName $lastName",
          'photoUrl': event.photoUrl,
          'companyName': event.companyName,
        },
      ),
    );
  }

  @override
  Future<void> close() {
    _textRecognitionService.dispose();
    return super.close();
  }
}
