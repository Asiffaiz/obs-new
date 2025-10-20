import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_back_button.dart';
import 'package:voicealerts_obs/features/agreements/data/repositories/mock_agreements_repository_impl.dart';
import 'package:voicealerts_obs/features/agreements/data/services/agreements_service.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_bloc.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/archived_agreements_screen.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/signed_agreements_screen.dart';

class SignedAgreementsMainScreen extends StatefulWidget {
  final int? tabSelected;
  const SignedAgreementsMainScreen({super.key, this.tabSelected});

  @override
  State<SignedAgreementsMainScreen> createState() =>
      _SignedAgreementsMainScreenState();
}

class _SignedAgreementsMainScreenState extends State<SignedAgreementsMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.tabSelected != null) {
      _tabController.animateTo(widget.tabSelected!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Signed Agreements'),
        centerTitle: true,
        // leading: const Padding(
        //   padding: EdgeInsets.only(left: 4), // Adjust for spacing
        //   child: CustomBackButton(),
        // ),
      ),
      body: BlocProvider(
        create:
            (context) => AgreementsBloc(
              agreementsRepository: MockAgreementsRepositoryImpl(
                agreementsService: GetIt.instance<AgreementService>(),
              ),
            ),
        child: Column(
          children: [
            // _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: [
                  SignedAgreementsScreen(),
                  // Archived Agreements Tab
                  ArchivedAgreementsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Signed Agreements',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 43,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          // Border for unselected tabs
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
          // TabBar on top with transparent background to let borders show through
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Signed Agreements'),
              Tab(text: 'Archived Agreements'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            indicator: BoxDecoration(
              color: AppColors.appButtonColor,
              borderRadius: BorderRadius.circular(25),
              // No border on selected tab
              border: null,
            ),
            dividerHeight: 0,
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.all(4),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            dividerColor: Colors.transparent,
          ),
        ],
      ),
    );

    //   Container(
    //     decoration: const BoxDecoration(
    //       border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
    //     ),
    //     child: TabBar(
    //       controller: _tabController,
    //       labelColor: Colors.white,
    //       unselectedLabelColor: Colors.black87,
    //       indicator: BoxDecoration(
    //         color: AppColors.appButtonColor,
    //         borderRadius: BorderRadius.circular(25),
    //         // No border on selected tab
    //         border: null,
    //       ),
    //       dividerHeight: 0,
    //       indicatorSize: TabBarIndicatorSize.tab,
    //       padding: const EdgeInsets.all(4),
    //       labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    //       unselectedLabelStyle: const TextStyle(fontSize: 14),
    //       dividerColor: Colors.transparent,
    //       tabs: const [
    //         Tab(text: 'Signed Agreements'),
    //         Tab(text: 'Archived Agreements'),
    //       ],
    //     ),
    //   );
  }
}
