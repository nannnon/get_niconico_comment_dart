import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main(List<String> args) async {
  var nnws = NicoNamaWebSocket();
  nnws.connect('ch2646436');
}

class NicoNamaWebSocket {
  io.WebSocket? _watchingServerWS;
  io.WebSocket? _commentServerWS;

  NicoNamaWebSocket() {}

  void connect(String ch) async {
    if (_watchingServerWS != null || _commentServerWS != null) {
      throw Exception('alread called');
    }

    final watchingServerWebSocketUrl = await _getWatchingServerWebSocketUrl(ch);
    _connectWatchingServer(watchingServerWebSocketUrl);
  }

  Future<String> _getWatchingServerWebSocketUrl(String ch) async {
    final url = Uri.parse('https://live.nicovideo.jp/watch/' + ch);
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to get');
    }

    final document = parser.parse(res.body);
    final eddp =
        document.getElementById('embedded-data')?.attributes['data-props'];
    final eddpJson = convert.jsonDecode(eddp!) as Map<String, dynamic>;
    final webSocketUrl = eddpJson['site']['relive']['webSocketUrl'];

    return webSocketUrl;
  }

  Future<void> _connectWatchingServer(String webSocketUrl) async {
    if (_watchingServerWS != null) {
      throw Exception('already called');
    }

    _watchingServerWS = await io.WebSocket.connect(webSocketUrl);
    _watchingServerWS!.listen(_processWatchingServerMessage, onError: (error) {
      print('error:$error');
    }, onDone: () {
      print('socket closed');
    }, cancelOnError: true);

    const message1 =
        '{"type":"startWatching","data":{"stream":{"quality":"abr","protocol":"hls","latency":"low","chasePlay":false},"room":{"protocol":"webSocket","commentable":true},"reconnect":false}}';
    const message2 = '{"type":"getAkashic","data":{"chasePlay":false}}';
    _watchingServerWS!.add(message1);
    _watchingServerWS!.add(message2);

    try {
      await _watchingServerWS!.done;
      print('WebSocket done');
    } catch (error) {
      print('WebSocket done with error $error');
    }
  }

  void _processWatchingServerMessage(dynamic message) {
    var msg = message.toString();
    bool room_exists = msg.indexOf('room') >= 0;
    bool ping_exists = msg.indexOf('ping') >= 0;

    if (room_exists) {
      var msgJson = convert.jsonDecode(msg) as Map<String, dynamic>;
      var commentServerWebSocketUrl = msgJson['data']['messageServer']['uri'];
      var threadId = msgJson['data']['threadId'];
      String sendData =
          '[{"ping":{"content":"rs:0"}},{"ping":{"content":"ps:0"}},{"thread":{"thread":"${threadId}","version":"20061206","user_id":"guest","res_from":-150,"with_global":1,"scores":1,"nicoru":0}},{"ping":{"content":"pf:0"}},{"ping":{"content":"rf:0"}}]';
      _connectCommentServer(commentServerWebSocketUrl, sendData);
    }

    if (ping_exists) {
      _watchingServerWS!.add('{"type":"pong"}');
      _watchingServerWS!.add('{"type":"keepSeat"}');
    }
  }

  Future<void> _connectCommentServer(
      String webSocketUrl, String sendData) async {
    if (_commentServerWS != null) {
      throw Exception('already called');
    }

    _commentServerWS = await io.WebSocket.connect(webSocketUrl, headers: {
      'Sec-WebSocket-Extensions': 'permessage-deflate; client_max_window_bits',
      'Sec-WebSocket-Protocol': 'msg.nicovideo.jp#json',
    });
    _commentServerWS!.listen(_processCommentSeverMessage, onError: (error) {
      print('error:$error');
    }, onDone: () {
      print('socket closed');
    }, cancelOnError: true);

    _commentServerWS!.add(sendData);

    try {
      await _commentServerWS!.done;
      print('WebSocket done');
    } catch (error) {
      print('WebSocket done with error $error');
    }
  }

  void _processCommentSeverMessage(dynamic message) {
    final msg = message.toString();
    bool chat_exists = msg.indexOf('chat') >= 0;
    bool ping_exists = msg.indexOf('ping') >= 0;

    if (chat_exists) {
      final messageJson =
          convert.jsonDecode(message.toString()) as Map<String, dynamic>;
      String comment = messageJson['chat']['content'];
      print(comment);
    }

    if (ping_exists) {
      _commentServerWS!.add('{"type":"pong"}');
      _commentServerWS!.add('{"type":"keepSeat"}');
    }
  }
}
