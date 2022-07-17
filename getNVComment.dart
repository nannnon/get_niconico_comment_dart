import 'dart:math';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  String movieId = 'sm40756637';
  var headers = {'X-Frontend-Id': '6', 'X-Frontend-Version': '0'};

  Random random = Random();

  const String chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  const int charsLength = 10;
  String randomChars = String.fromCharCodes(Iterable.generate(
      charsLength, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

  int num = 10;
  int order = 12;
  int min = pow(num, order).round();
  int max = pow(num, order + 1).round();
  int randomNumber = (random.nextDouble() * (max - min) + min).round();

  String actionTrackId = "${randomChars}_${randomNumber}";

  Uri url = Uri(
      scheme: 'https',
      host: 'www.nicovideo.jp',
      path: "/api/watch/v3_guest/${movieId}",
      queryParameters: {'actionTrackId': actionTrackId});

  http.Response res = await http.post(url, headers: headers);

  var jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;

  var nvComment = jsonRes['data']['comment']['nvComment'];

  var headers2 = {
    'X-Frontend-Id': '6',
    'X-Frontend-Version': '0',
    'Content-Type': 'application/json'
  };

  var params = {
    'params': nvComment['params'],
    'additionals': {},
    'threadKey': nvComment['threadKey']
  };

  Uri url2 = Uri.parse(nvComment['server'] + '/v1/threads');

  var res2 = await http.post(url2,
      body: convert.jsonEncode(params), headers: headers2);

  String res2Body = convert.utf8.decode(res2.bodyBytes);

  var jsonRes2 = convert.jsonDecode(res2Body) as Map<String, dynamic>;

  for (int i = 0; i < 10; ++i) {
    print(jsonRes2['data']['threads'][1]['comments'][i]['body']);
  }
}
