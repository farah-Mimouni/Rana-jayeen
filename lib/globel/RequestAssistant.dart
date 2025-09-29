import 'dart:convert';
import 'package:http/http.dart' as http;


class RequestAssistant {
  static Future<dynamic> receiveRequest(String url) async {
    http.Response httpResponse = await http.get(Uri.parse(url));
    try {
      if (httpResponse.statusCode == 200) {
        String reponseData = httpResponse.body;
        var decodeReponseData = jsonDecode(reponseData);
        return decodeReponseData;
      } else {
        return "error occured .faild No response";
      }
    } catch (exp) {
      return "error occured .faild No response";
    }
  }
}
