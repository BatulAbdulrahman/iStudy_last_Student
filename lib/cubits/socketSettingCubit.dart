import 'dart:async';
import 'dart:convert';

import 'package:eschool/data/models/chatMessage.dart';
import 'package:eschool/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketSettingState {}

class SocketConnectSuccess extends SocketSettingState {}

class SocketConnectFailure extends SocketSettingState {}

class SocketMessageReceived extends SocketSettingState {
  final String from;
  final String to;
  final ChatMessage message;

  SocketMessageReceived({
    required this.from,
    required this.to,
    required this.message,
  });
}

class SocketSettingCubit extends Cubit<SocketSettingState> {
  SocketSettingCubit() : super(SocketSettingState());

  late Uri wsUrl;
  late WebSocketChannel channel;
  StreamSubscription<dynamic>? streamSubscription;
Future<void> init({required int userId}) async {
  if (userId <= 0) {
    debugPrint("Invalid user ID provided for socket connection.");
    emit(SocketConnectFailure());
    return;
  }

  wsUrl = Uri.parse(socketUrl);

  try {
    channel = IOWebSocketChannel.connect(
      wsUrl,
      pingInterval: socketPingInterval,
    );

    // Register user
    channel.sink.add(json.encode({
      "command": SocketEvent.register.name,
      "userId": userId,
    }));
    emit(SocketConnectSuccess());
    debugPrint("Socket connected : $userId");

    streamSubscription = channel.stream.listen((event) {
      final eventMap = json.decode(event) as Map<String, dynamic>;

      if (eventMap["command"] == SocketEvent.message.name &&
          eventMap['to'].toString() == userId.toString()) {
        debugPrint(eventMap.toString());
        emit(
          SocketMessageReceived(
            from: eventMap['from'].toString(),
            to: eventMap['to'].toString(),
            message: ChatMessage.fromJson(
                eventMap['message'] as Map<String, dynamic>),
          ),
        );
      }
    });
  } catch (error) {
    debugPrint("Socket connection error: $error");
    emit(SocketConnectFailure());
  }
}


  void sendMessage({
    required int userId,
    required int receiverId,
    required ChatMessage message,
  }) async {
    channel.sink.add(
      json.encode({
        "command": SocketEvent.message.name,
        "from": userId,
        "to": receiverId,
        "message": message.toJson(),
      }),
    );
  }

  @override
  Future<void> close() async {
    await channel.sink.close();
    streamSubscription?.cancel();
    super.close();
  }
}
