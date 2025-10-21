import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/app_ctrl.dart';
import 'screens/agent_screen.dart';
import 'screens/audio_call_screen.dart';
import 'screens/welcome_screen.dart';
import 'ui/color_pallette.dart' show LKColorPaletteLight, LKColorPaletteDark;
import 'widgets/app_layout_switcher.dart';

final appCtrl = AppCtrl();

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({super.key});

  @override
  Widget build(BuildContext ctx) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: appCtrl),
      ChangeNotifierProvider.value(value: appCtrl.roomContext),
    ],
    child: Builder(
      builder:
          (ctx) => Selector<AppCtrl, AppScreenState>(
            selector: (ctx, appCtx) => appCtx.appScreenState,
            builder: (ctx, screen, _) {
              return const AudioCallScreen();
              // if (screen == AppScreenState.audioCall) {
              //   return const AudioCallScreen();
              // }
              // return AppLayoutSwitcher(
              //   frontBuilder: (ctx) => const WelcomeScreen(),
              //   backBuilder: (ctx) => const AgentScreen(),
              //   isFront: screen == AppScreenState.welcome,
              // );
            },
          ),
    ),
  );
}
