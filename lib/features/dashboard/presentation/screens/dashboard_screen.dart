import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/features/ai%20agent/app.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/bloc/bloc/dashboard_bloc.dart';
import 'package:voicealerts_obs/features/documents/presentation/screens/documents_screen.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/client_assigned_forms_screen.dart';
import 'package:voicealerts_obs/features/products/presentation/screens/products_screen.dart';

import '../../../../config/routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/services/menu_service.dart';
import '../../domain/models/menu_item_model.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_bottom_nav.dart';
import '../widgets/dashboard_drawer.dart';
import '../widgets/dashboard_home_content.dart';
import '../widgets/dashboard_side_menu.dart';
import 'profile_screen.dart';
import 'webview_content_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedMenuId = 'dashboard';
  late Widget _currentContent;
  String _userName = '';
  String _userEmail = '';
  List<MenuItemModel> _menuItems = [];
  int _selectedIndex = 0;
  bool _isLoadingMenu = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMenuItems();
    _currentContent = _buildDashboardHomeContent();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<DashboardBloc>().add(LoadDashboardData());
    });
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Access the AuthBloc state directly
  //   final authState = context.read<AuthBloc>().state;
  //   if (authState.isApiAuthenticated && authState.apiUserData != null) {
  //     final userData = authState.apiUserData!;
  //     setState(() {
  //       _userName = userData['name'] ?? 'User';
  //       _userEmail = userData['email'] ?? '';
  //     });
  //   }
  // }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final userData = await authService.getUserData();

    if (mounted) {
      setState(() {
        _userName = userData['name'] ?? 'User';
        _userEmail = userData['email'] ?? '';
      });
    }
  }

  // Get user data from shared preferences
  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> userData = {};
    const String _tokenKey = 'client_tkn__';
    const String _accountNoKey = 'client_acn__';

    const String _emailKey = 'client_eml__';
    const String _companyNameKey = 'client_comp_nme__';
    const String _userTypeKey = 'client_user_type__';

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return {};
    }

    userData['token'] = prefs.getString(_tokenKey) ?? '';
    userData['accountno'] = prefs.getString(_accountNoKey) ?? '';

    userData['email'] = prefs.getString(_emailKey) ?? '';
    userData['comp_name'] = prefs.getString(_companyNameKey) ?? '';
    userData['user_type'] = prefs.getString(_userTypeKey) ?? '';

    return userData;
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoadingMenu = true;
    });

    try {
      final menuService = MenuService();
      final menuItems = await menuService.fetchMenuItems();

      if (mounted) {
        setState(() {
          _menuItems = menuItems;
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      print('Error loading menu items: $e');
      // Fallback to static menu if API fails
      _initializeStaticMenu();
    }
  }

  void _initializeStaticMenu() async {
    final userData = await getUserData();
    final url =
        "https://agents.hugeuc.me/client/agreements"
        "?view_type=mobile"
        "&token=${userData["token"]}"
        "&accountno=${userData["accountno"]}"
        "&email=${userData["email"]}"
        "&comp_name=${userData["comp_name"]}"
        "&user_type=${userData["user_type"]}";
    print(url);
    setState(() {
      _menuItems = [
        MenuItemModel(
          id: 'dashboard',
          title: 'Dashboard',
          icon: Icons.dashboard,
        ),
        MenuItemModel(
          id: 'agreements',
          title: 'Agreements',
          icon: Icons.description,
          children: [
            MenuItemModel(
              id: 'signed_agreements',
              title: 'Signed Agreements',
              icon: Icons.check_circle_outline,
              url: null,
            ),
            MenuItemModel(
              id: 'unsigned_agreements',
              title: 'Unsigned Agreements',
              icon: Icons.assignment,
              url: null,
            ),
          ],
        ),
        MenuItemModel(
          id: 'credit_application',
          title: 'Credit Application',
          icon: Icons.credit_card,
          url: 'https://test.onboardsoft.com/',
        ),
        MenuItemModel(
          id: 'kyc_form',
          title: 'KYC Form',
          icon: Icons.person_search,
          url: 'https://dev-agents.onboardsoft.me/client/kyc-form',
        ),
        MenuItemModel(
          id: 'reports',
          title: 'Reports',
          icon: Icons.report,
          url: null,
        ),
        MenuItemModel(
          id: 'products_services',
          title: 'Product & Services',
          icon: Icons.inventory,
          url: null,
        ),
        MenuItemModel(
          id: 'sub_clients',
          title: 'Sub Clients',
          icon: Icons.people,
          url: 'https://dev-agents.onboardsoft.me/client/sub-clients',
        ),
        MenuItemModel(
          id: 'documents',
          title: 'Documents',
          icon: Icons.folder,
          url: null,
        ),
        MenuItemModel(
          id: 'forms',
          title: 'Forms',
          icon: Icons.assignment,
          url: null,
        ),
      ];
      _isLoadingMenu = false;
    });
  }

  void _handleMenuItemTap(MenuItemModel item) {
    if (item.hasChildren) {
      setState(() {
        _menuItems =
            _menuItems.map((menuItem) {
              if (menuItem.id == item.id) {
                return menuItem.copyWith(isExpanded: !menuItem.isExpanded);
              }
              return menuItem;
            }).toList();
      });
    } else {
      setState(() {
        _selectedMenuId = item.id;

        // Close the drawer on mobile
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
        print(item.id);
        // Handle special menu items by navigating to their routes
        if (item.id == 'signed_agreements') {
          setState(() {
            _selectedMenuId = 'dashboard';
            _currentContent = _buildDashboardHomeContent();
          });
          context.push(AppRoutes.signedAgreements);
          return;
        } else if (item.id == 'unsigned_agreements') {
          setState(() {
            _selectedMenuId = 'dashboard';
            _currentContent = _buildDashboardHomeContent();
          });
          context.push(AppRoutes.optionalAgreements);
          return;
        } else if (item.id == 'reports') {
          setState(() {
            _selectedMenuId = 'dashboard';
            _currentContent = _buildDashboardHomeContent();
          });
          context.push(AppRoutes.reports);
          return;
        } else if (item.id == 'client_assigned_forms') {
          setState(() {
            _selectedMenuId = 'dashboard';
            _currentContent = _buildDashboardHomeContent();
          });
          // context.push(AppRoutes.clientAssignedForms);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ClientAssignedFormsScreen(
                    title: 'Forms',
                    isFrom: 'side_menu_forms',
                  ),
            ),
          );
          return;
        } else if (item.id == 'documents') {
          setState(() {
            _selectedMenuId = 'dashboard';
            _currentContent = _buildDashboardHomeContent();
          });
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentsScreen()),
          );
        } else if (item.id == 'products_services') {
          setState(() {
            _selectedMenuId = 'dashboard';
            _currentContent = _buildDashboardHomeContent();
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductsScreen(isFromBottomNav: false),
            ),
          );
        }

        // Update content based on selected menu item
        if (item.url != null) {
          _currentContent = WebViewContentScreen(
            url: item.url!,
            title: item.title,
            onBack: () {
              setState(() {
                _selectedMenuId = 'dashboard';
                _currentContent = _buildDashboardHomeContent();
              });
            },
          );
        } else if (item.id == 'dashboard') {
          _currentContent = _buildDashboardHomeContent();
        }
      });
    }
  }

  void _handleBottomNavTap(int index) {
    // Don't do anything if the tab is already selected
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;

      // Make home tab functional
      if (index == 0) {
        _selectedMenuId = 'dashboard';
        _currentContent = _buildDashboardHomeContent();
      }
      // Client assigned forms tab
      else if (index == 1) {
        _selectedMenuId = 'client_assigned_forms';
        _currentContent = ClientAssignedFormsScreen(
          title: null,
          isFrom: 'dashboard_forms',
        );
      }
      // Agreements tab
      else if (index == 2) {
        // Update the menu ID and find the agreements menu item
        // _selectedMenuId = 'agreements';
        // for (var item in _menuItems) {
        //   if (item.id == 'agreements') {
        //     // Expand the agreements menu
        //     _menuItems =
        //         _menuItems.map((menuItem) {
        //           if (menuItem.id == 'agreements') {
        //             return menuItem.copyWith(isExpanded: true);
        //           }
        //           return menuItem;
        //         }).toList();
        //     break;
        //   }
        // }

        // Product & Services tab

        _selectedMenuId = 'products_services';
        _currentContent = ProductsScreen(isFromBottomNav: true);
      }
      // Profile tab
      else if (index == 3) {
        _selectedMenuId = 'user_profile';
        _currentContent = ProfileScreen(
          userName: _userName,
          userEmail: _userEmail,
        );
      }
      // Other tabs are just visual for now
    });
  }

  // Kept for future use when implementing sign out functionality
  // void _signOut() {
  //   context.read<AuthBloc>().add(const SignOutRequested());
  //   context.go(AppRoutes.signIn);
  // }

  // Helper method to handle menu item selection from DashboardHomeContent
  void _handleMenuSelection(String menuId, String? url) {
    // Find the menu item with this ID
    for (var item in _menuItems) {
      if (item.id == menuId) {
        _handleMenuItemTap(item);
        return;
      }

      // Check in children
      if (item.hasChildren) {
        for (var child in item.children) {
          if (child.id == menuId) {
            _handleMenuItemTap(child);
            return;
          }
        }
      }
    }
  }

  Widget _buildDashboardHomeContent() {
    return DashboardHomeContent(onMenuItemSelected: _handleMenuSelection);
  }

  // Get the title for the current page
  String _getPageTitle() {
    // Find the menu item that matches the current selected ID
    for (var item in _menuItems) {
      if (item.id == _selectedMenuId) {
        return item.title;
      }

      // Check children
      if (item.hasChildren) {
        for (var child in item.children) {
          if (child.id == _selectedMenuId) {
            return child.title;
          }
        }
      }
    }

    return "Convoso";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final bool isMainDashboard = _selectedMenuId == 'dashboard';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isApiAuthenticated && state.apiUserData != null) {
          final userData = state.apiUserData!;
          setState(() {
            _userName = userData['name'] ?? 'User';
            _userEmail = userData['email'] ?? '';
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: DashboardAppBar(
          userName: _userName,
          isMainDashboard: isMainDashboard,
          isDesktop: isDesktop,
          pageTitle: _getPageTitle(),
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onBackTap:
              isMainDashboard
                  ? null
                  : () {
                    setState(() {
                      _selectedMenuId = 'dashboard';
                      _currentContent = _buildDashboardHomeContent();
                      _selectedIndex = 0; // Reset bottom nav selection to home
                    });
                  },
        ),
        drawer:
            isDesktop
                ? null
                : _selectedIndex == 0
                ? DashboardDrawer(
                  userName: _userName,
                  userEmail: _userEmail,
                  menuItems: _menuItems,
                  selectedMenuId: _selectedMenuId,
                  onMenuItemTap: _handleMenuItemTap,
                  isLoading: _isLoadingMenu,
                )
                : null,
        body: Row(
          children: [
            // Side menu for desktop
            if (isDesktop)
              DashboardSideMenu(
                userName: _userName,
                userEmail: _userEmail,
                menuItems: _menuItems,
                selectedMenuId: _selectedMenuId,
                onMenuItemTap: _handleMenuItemTap,
                isLoading: _isLoadingMenu,
              ),

            // Main content area
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _currentContent,
              ),
            ),
          ],
        ),
        bottomNavigationBar:
        // isDesktop
        //     ? null
        //     :
        DashboardBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: _handleBottomNavTap,
        ),

        floatingActionButton: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Purple → Blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.mic, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VoiceAssistantApp()),
              );
            },
          ),
        ),
      ),
    );
  }
}
