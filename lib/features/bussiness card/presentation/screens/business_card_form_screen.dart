// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:http/http.dart' as http;
// import 'package:voicealerts_obs/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:voicealerts_obs/features/auth/presentation/bloc/auth_event.dart';
// import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';

// import '../bloc/business_card_bloc.dart';
// import '../bloc/business_card_event.dart';
// import '../bloc/business_card_state.dart';
// import '../widgets/loading_state.dart';

// class BusinessCardFormScreen extends StatefulWidget {
//   final int cardId;
//   final String? imagePath;

//   const BusinessCardFormScreen({
//     super.key,
//     required this.cardId,
//     this.imagePath,
//   });

//   @override
//   State<BusinessCardFormScreen> createState() => _BusinessCardFormScreenState();
// }

// class _BusinessCardFormScreenState extends State<BusinessCardFormScreen> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void _checkUser(BusinessCard businessCard) async {
//     context.read<AuthBloc>().add(
//       SignInWithBusinessCardRequested(
//         email: businessCard.email,
//         businessCardUser: businessCard,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<BusinessCardBloc, BusinessCardState>(
//       listener: (context, state) {
//         if (state is BusinessCardDetailLoaded) {
//           _checkUser(state.businessCard);
//         }
//       },
//     );
//   }
// }
