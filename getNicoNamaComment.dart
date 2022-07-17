import 'dart:io' as io;
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main(List<String> args) async {
  final webSocketUrl = await getWebSocketUrl();
  print(webSocketUrl);

  var watchingWS = await connectWatchingServer(webSocketUrl);

  try {
    await watchingWS.done;
    print('WebSocket done');
  } catch (error) {
    print('WebSocket done with error $error');
  }
}

Future<String> getWebSocketUrl() async {
  final url = Uri.parse('https://live.nicovideo.jp/watch/ch2646436');
  final res = await http.get(url);
  if (res.statusCode != 200) {
    print('ERROR: ${res.statusCode}');
    io.exit(1);
  }

  final document = parser.parse(res.body);
  final eddp =
      document.getElementById('embedded-data')?.attributes['data-props'];
  final eddpJson = convert.jsonDecode(eddp!) as Map<String, dynamic>;
  final webSocketUrl = eddpJson['site']['relive']['webSocketUrl'];

  return webSocketUrl;
}

Future<io.WebSocket> connectWatchingServer(String webSocketUrl) async {
  io.WebSocket watchingWS = await io.WebSocket.connect(webSocketUrl);
  watchingWS.listen((message) {
    print('message:$message');
  }, onError: (error) {
    print('error:$error');
  }, onDone: () {
    print('socket closed');
  }, cancelOnError: true);

  const message1 =
      '{"type":"startWatching","data":{"stream":{"quality":"abr","protocol":"hls","latency":"low","chasePlay":false},"room":{"protocol":"webSocket","commentable":true},"reconnect":false}}';
  const message2 = '{"type":"getAkashic","data":{"chasePlay":false}}';
  watchingWS.add(message1);
  watchingWS.add(message2);

  return watchingWS;
}
