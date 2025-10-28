import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../exts.dart';
import '../services/token_service.dart';

enum AppScreenState { welcome, agent, audioCall }

enum AgentScreenState { visualizer, transcription }

enum ConnectionState { disconnected, connecting, connected }

class AppCtrl extends ChangeNotifier {
  static const uuid = Uuid();
  static final _logger = Logger('AppCtrl');

  // States
  AppScreenState appScreenState = AppScreenState.welcome;
  ConnectionState connectionState = ConnectionState.disconnected;
  AgentScreenState agentScreenState = AgentScreenState.visualizer;

  //Test
  bool isUserCameEnabled = false;
  bool isScreenshareEnabled = false;
  bool isHoldEnabled = false;
  final messageCtrl = TextEditingController();
  final messageFocusNode = FocusNode();

  late final sdk.Room room = sdk.Room(
    roomOptions: const sdk.RoomOptions(enableVisualizer: true),
  );
  late final roomContext = components.RoomContext(room: room);

  // Add event listeners for debugging
  bool _roomListenersInitialized = false;

  final tokenService = TokenService();

  bool isSendButtonEnabled = false;

  // Timer for checking agent connection
  Timer? _agentConnectionTimer;

  AppCtrl() {
    final format = DateFormat('HH:mm:ss');
    // configure logs for debugging
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      debugPrint('${format.format(record.time)}: ${record.message}');
    });

    messageCtrl.addListener(() {
      final newValue = messageCtrl.text.isNotEmpty;
      if (newValue != isSendButtonEnabled) {
        isSendButtonEnabled = newValue;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    messageCtrl.dispose();
    _cancelAgentTimer();
    super.dispose();
  }

  void sendMessage() async {
    isSendButtonEnabled = false;

    final text = messageCtrl.text;
    messageCtrl.clear();
    notifyListeners();

    final lp = room.localParticipant;
    if (lp == null) return;

    final nowUtc = DateTime.now().toUtc();
    final segment = sdk.TranscriptionSegment(
      id: uuid.v4(),
      text: text,
      firstReceivedTime: nowUtc,
      lastReceivedTime: nowUtc,
      isFinal: true,
      language: 'en',
    );
    roomContext.insertTranscription(
      components.TranscriptionForParticipant(segment, lp),
    );

    await lp.sendText(text, options: sdk.SendTextOptions(topic: 'lk.chat'));
  }

  void toggleUserCamera(components.MediaDeviceContext? deviceCtx) {
    isUserCameEnabled = !isUserCameEnabled;
    isUserCameEnabled ? deviceCtx?.enableCamera() : deviceCtx?.disableCamera();
    notifyListeners();
  }

  void toggleScreenShare() {
    isScreenshareEnabled = !isScreenshareEnabled;
    notifyListeners();
  }

  void toggleAgentScreenMode() {
    agentScreenState =
        agentScreenState == AgentScreenState.visualizer
            ? AgentScreenState.transcription
            : AgentScreenState.visualizer;
    notifyListeners();
  }

  void _setupRoomListeners() {
    if (_roomListenersInitialized) return;

    _logger.info("Setting up room event listeners");

    // Listen for participant connected events
    room.addListener(() {
      _logger.info("Room state changed: ${room.connectionState}");

      // Log remote participants whenever the room state changes
      _logger.info(
        "Remote participants count: ${room.remoteParticipants.length}",
      );
      if (room.remoteParticipants.isNotEmpty) {
        room.remoteParticipants.forEach((sid, participant) {
          _logger.info(
            "Remote participant: ${participant.identity} (${participant.sid})",
          );
          _logger.info("Participant kind: ${participant.kind}");
        });
      }

      // Check if room disconnected
      if (room.connectionState == sdk.ConnectionState.disconnected) {
        _logger.warning("Room disconnected - checking reason");
        // Reset UI state when room disconnects
        connectionState = ConnectionState.disconnected;

        // Show toast message to inform the user
        // Fluttertoast.showToast(
        //     msg: "Agent disconnected. Please try again later.",
        //     toastLength: Toast.LENGTH_LONG,
        //     gravity: ToastGravity.BOTTOM,
        //     timeInSecForIosWeb: 3,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     fontSize: 16.0);

        notifyListeners();
      }

      notifyListeners();
    });

    // Add a listener for disconnection events
    room.createListener().on<sdk.RoomDisconnectedEvent>((event) {
      _logger.severe("Room disconnected event received");
      // Reset UI state when disconnection event is received
      connectionState = ConnectionState.disconnected;

      // Show toast message to inform the user about the disconnection
      // Fluttertoast.showToast(
      //     msg: "Connection to agent lost. Please try again later.",
      //     toastLength: Toast.LENGTH_LONG,
      //     gravity: ToastGravity.BOTTOM,
      //     timeInSecForIosWeb: 3,
      //     backgroundColor: Colors.red,
      //     textColor: Colors.white,
      //     fontSize: 16.0);

      notifyListeners();
    });

    _roomListenersInitialized = true;
  }

  void connect() async {
    _logger.info("Connect....");
    connectionState = ConnectionState.connecting;
    notifyListeners();

    try {
      // Set up room event listeners
      _setupRoomListeners();

      // Direct connection with hardcoded credentials from portal
      const serverUrl = "wss://obs-v760rz4i.livekit.cloud";
      const token =
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiTWF5YSIsInZpZGVvIjp7InJvb21Kb2luIjp0cnVlLCJyb29tIjoibW9pbmNfcm9vbSIsImNhblB1Ymxpc2giOnRydWUsImNhblN1YnNjcmliZSI6dHJ1ZSwiY2FuUHVibGlzaERhdGEiOnRydWV9LCJzdWIiOiI2ZTM5OTg3YS1kODFmLTQ3ZTUtYmQ0MC0yOGY0MGU5ZDExNDgiLCJpc3MiOiJBUEk4Ymhvblg3RUhvenAiLCJuYmYiOjE3NjEzMzM2NDEsImV4cCI6MTc2MTM1NTI0MX0.1gSWxqem92FvqucQ8HMsHAESRmB1v9OcS6oJrZ0VbHA";

      // From your logs, I can see that the connection is initially successful
      // but then disconnects with a timeout error. This could be due to:
      // 1. Identity conflicts ("string" is not a unique identity)
      // 2. Connection timeout issues
      // 3. Permission conflicts with the agent participant

      _logger.info("Using direct connection with hardcoded token");

      // Decode token to understand what's in it
      final parts = token.split('.');
      if (parts.length > 1) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        _logger.info("Token payload: $decoded");
      }

      _logger.info("Connecting to LiveKit server: $serverUrl");

      // Log the current state of remote participants before connecting
      _logger.info(
        "Remote participants before connect: ${room.remoteParticipants.length}",
      );

      // Connect to the room with direct credentials
      await room.connect(serverUrl, token);

      _logger.info("Room connection state: ${room.connectionState}");
      _logger.info("Local participant: ${room.localParticipant?.identity}");
      _logger.info("Room name: ${room.name}");

      // Enable microphone
      await room.localParticipant?.setMicrophoneEnabled(true);
      _logger.info("Microphone enabled");

      // Log the current state of remote participants after connecting
      _logger.info(
        "Remote participants after connect: ${room.remoteParticipants.length}",
      );
      if (room.remoteParticipants.isNotEmpty) {
        room.remoteParticipants.forEach((sid, participant) {
          _logger.info(
            "Remote participant: ${participant.identity} (${participant.sid})",
          );
          _logger.info("Participant kind: ${participant.kind}");
          _logger.info("Participant state: ${participant.connectionQuality}");
        });
      } else {
        _logger.warning("No remote participants found after connection");
      }

      connectionState = ConnectionState.connected;

      // If we're in audio call screen, stay there, otherwise go to agent screen
      if (appScreenState != AppScreenState.audioCall) {
        appScreenState = AppScreenState.agent;
      }

      // Start the timer to check for AGENT participant
      _startAgentConnectionTimer();

      notifyListeners();
    } catch (error) {
      _logger.severe('Connection error: $error');

      connectionState = ConnectionState.disconnected;
      // appScreenState = AppScreenState.welcome;
      notifyListeners();
    }
  }

  void disconnect() {
    room.disconnect();
    _cancelAgentTimer();

    // Update states
    connectionState = ConnectionState.disconnected;

    // If we're in audio call screen, stay there, otherwise go back to welcome
    if (appScreenState != AppScreenState.audioCall) {
      appScreenState = AppScreenState.welcome;
    }
    agentScreenState = AgentScreenState.visualizer;

    notifyListeners();
  }

  // Start a 60-second timer to check for agent connection
  void _startAgentConnectionTimer() {
    _cancelAgentTimer(); // Cancel any existing timer
    _logger.info("Starting 60-second timer to check for AGENT participant...");

    _agentConnectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // First check if room is still connected
      if (room.connectionState == sdk.ConnectionState.disconnected) {
        _logger.warning(
          "Room disconnected during agent check, cancelling timer",
        );
        _cancelAgentTimer();
        connectionState = ConnectionState.disconnected;

        // Show toast message to inform the user
        // Fluttertoast.showToast(
        //     msg: "Connection lost while waiting for agent.",
        //     toastLength: Toast.LENGTH_LONG,
        //     gravity: ToastGravity.BOTTOM,
        //     timeInSecForIosWeb: 3,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     fontSize: 16.0);

        notifyListeners();
        return;
      }

      // Log detailed information about remote participants every 5 seconds
      if (timer.tick % 5 == 0) {
        _logger.info(
          "Timer tick: ${timer.tick}, checking remote participants...",
        );
        _logger.info("Room state: ${room.connectionState}");
        _logger.info(
          "Remote participants count: ${room.remoteParticipants.length}",
        );

        if (room.remoteParticipants.isEmpty) {
          _logger.warning("No remote participants found");
        } else {
          room.remoteParticipants.forEach((sid, participant) {
            _logger.info(
              "Remote participant: ${participant.identity} (${participant.sid})",
            );
            _logger.info("Participant kind: ${participant.kind}");
            _logger.info("Participant metadata: ${participant.metadata}");
            _logger.info("Participant attributes: ${participant.attributes}");
            _logger.info(
              "Participant tracks: ${participant.trackPublications.length}",
            );
          });
        }
      }

      // Check if there's an agent participant
      final hasAgent = room.remoteParticipants.values.any(
        (participant) => participant.isAgent,
      );

      if (hasAgent) {
        _logger.info("AGENT participant found, cancelling timer");
        _cancelAgentTimer();
        return;
      }

      // If 60 seconds have elapsed and no agent found, disconnect
      if (timer.tick >= 60) {
        _logger.warning(
          "No AGENT participant found after 60 seconds, disconnecting...",
        );
        _cancelAgentTimer();

        // Show toast message to inform the user about the timeout
        // Fluttertoast.showToast(
        //     msg: "Could not connect to an agent. Please try again later.",
        //     toastLength: Toast.LENGTH_LONG,
        //     gravity: ToastGravity.BOTTOM,
        //     timeInSecForIosWeb: 3,
        //     backgroundColor: Colors.orange,
        //     textColor: Colors.white,
        //     fontSize: 16.0);

        disconnect();
      }
    });
  }

  // Cancel the agent connection timer
  void _cancelAgentTimer() {
    _agentConnectionTimer?.cancel();
    _agentConnectionTimer = null;
  }

  void toggleHold() {
    isHoldEnabled = !isHoldEnabled;
    notifyListeners();
  }
}
