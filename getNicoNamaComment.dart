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

    final webSocketUrl = await _getWatchingServerWebSocketUrl(ch);
    _connectWatchingServer(webSocketUrl);
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
    _watchingServerWS = await io.WebSocket.connect(webSocketUrl);
    _watchingServerWS!.listen(_processMessage, onError: (error) {
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

  void _processMessage(dynamic message) {
    print(message);
    //var msg = message.toString();
    //bool room_exists = msg.indexOf('room') >= 0;
    //bool ping_exists = msg.indexOf('ping') >= 0;

    //if (ping_exists) {}
  }
}
