import 'package:dartz/dartz.dart';
import 'package:voicealerts_obs/features/bussiness%20card/data/datasources/database_helper.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';

class BusinessCardRepository {
  final DatabaseHelper _databaseHelper;

  BusinessCardRepository(this._databaseHelper);

  Future<Either<String, List<BusinessCard>>> getAllBusinessCards() async {
    try {
      final cards = await _databaseHelper.getAllBusinessCards();
      return Right(cards);
    } catch (e) {
      return Left('Error fetching business cards: ${e.toString()}');
    }
  }

  Future<Either<String, BusinessCard?>> getBusinessCard(int id) async {
    try {
      final card = await _databaseHelper.getBusinessCard(id);
      return Right(card);
    } catch (e) {
      return Left('Error fetching business card: ${e.toString()}');
    }
  }

  Future<Either<String, int>> saveBusinessCard(
    BusinessCard businessCard,
  ) async {
    try {
      final id = await _databaseHelper.insertBusinessCard(businessCard);
      return Right(id);
    } catch (e) {
      return Left('Error saving business card: ${e.toString()}');
    }
  }

  Future<Either<String, int>> updateBusinessCard(
    BusinessCard businessCard,
  ) async {
    try {
      final result = await _databaseHelper.updateBusinessCard(businessCard);
      return Right(result);
    } catch (e) {
      return Left('Error updating business card: ${e.toString()}');
    }
  }

  Future<Either<String, int>> deleteBusinessCard(int id) async {
    try {
      final result = await _databaseHelper.deleteBusinessCard(id);
      return Right(result);
    } catch (e) {
      return Left('Error deleting business card: ${e.toString()}');
    }
  }

  Future<Either<String, List<BusinessCard>>> searchBusinessCards(
    String query,
  ) async {
    try {
      final cards = await _databaseHelper.searchBusinessCards(query);
      return Right(cards);
    } catch (e) {
      return Left('Error searching business cards: ${e.toString()}');
    }
  }
}
