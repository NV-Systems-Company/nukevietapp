part of api;

enum HTTPMethod { post, put, delete }

extension ApiMethod on API {
  static Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static String convertMapToQueryParameter(Map<String, dynamic> params) {
    List<String> result = [];
    params.forEach((key, value) {
      result.add("$key=$value");
    });
    return result.join('&');
  }

  /// GET
  static Future<dynamic> getData(
      ApiPath api, Map<String, dynamic> params) async {
    final isOnline = await hasNetwork();
    if (isOnline == false) {
      throw NetworkException();
    }
    logger.info('getdata');
    logger.info('--[${api.name}] GET ${api.path} - params: $params');

    var accessToken = await Utils.getAppToken();
    //String params ='';
    logger.info(AppConstant.userId);
    String userid = AppConstant.userId;
    String basicAuth = base64Encode(utf8.encode('$userid:$accessToken'));
    Map<String, String> headers = { Global.shared.timestamp.toString() :  basicAuth};

    if (accessToken.isNotEmpty) {

      headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }


    if (params.isNotEmpty) {
      //String queryString = ApiMethod.convertMapToQueryParameter(params);
      //endpoint += '?$queryString';
    }

    try {
      logger.info(basicAuth);
      var response = await http.post(
          Uri.parse(Global.shared.endpoint(ApiPath.login.path)),
          headers: { Global.shared.timestamp.toString() : basicAuth},
          body: Global.shared.datapost
      );
      var jsonData = processResponse(response);
      logger.info(jsonData);
      logger.info(Global.shared.datapost);
      return jsonData;
    } catch (e) {
      throw e;
    }
  }

  /// POST
  static Future<dynamic> responseJSON(
      ApiPath api,
      Map<String, dynamic> params, {
        HTTPMethod method = HTTPMethod.post,
      }) async {
    final isOnline = await hasNetwork();
    if (isOnline == false) {
      throw NetworkException();
    }

    logger.info('--[${api.name}] POST ${api.path} - params: $params');

    var accessToken = await Utils.getAppToken();

    Map<String, String> headers = {};
    if (accessToken.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }

    final uri = Uri.https(Global.shared.authority, api.path);

    try {
      http.Response response;
      switch (method) {
        case HTTPMethod.post:
          response = await http.post(
            uri,
            body: params,
            headers: headers,
          );
          break;
        case HTTPMethod.put:
          response = await http.put(
            uri,
            body: params,
            headers: headers,
          );
          break;
        case HTTPMethod.delete:
          response = await http.delete(
            uri,
            headers: headers,
          );
          break;
      }
      var jsonData = processResponse(response);
      return jsonData;
    } catch (e) {
      throw e;
    }
  }

  /// TOKEN
  static Future<dynamic> getToken({String username, String password}) async {
    final isOnline = await hasNetwork();
    if (isOnline == false) {
      throw NetworkException();
    }
    String basicAuth = base64Encode(utf8.encode('$username:$password'));
    try {
     // Global.shared.timestamp = DateTime.now().microsecondsSinceEpoch+20000;
      var response = await http.post(
        Uri.parse(Global.shared.endpoint(ApiPath.login.path)),
        headers: { Global.shared.timestamp.toString() : basicAuth},
        body: Global.shared.datapost
      );

      var responseJson = processResponse(response);
      logger.info(responseJson);
      logger.info('oke return');
      return responseJson;
    } catch (e) {
      throw e;
    }
  }

  /// Renew TOKEN
  static Future<void> renewToken({String username, String accessToken}) async {
    final loginParam = await Utils.getLoginParam();

    String basicAuth = base64Encode(utf8.encode(loginParam));

    try {
      logger.info(Uri.parse(Global.shared.endpoint(ApiPath.login.path)));
      var response = await http.post(
        Uri.parse(Global.shared.endpoint(ApiPath.login.path)),
          headers: { Global.shared.timestamp.toString() : basicAuth},
          body: Global.shared.datapost
      );

      var utf8Decode = utf8.decode(response.bodyBytes);
      var responseJson = json.decode(utf8Decode);
      final token = NVToken.fromJson(responseJson);
      Utils.saveToken(token);
      return responseJson;
    } catch (e) {
      throw e;
    }

  }

  ///
  static dynamic processResponse(http.Response response) {
    logger.info(response); logger.info('hienket qua');
    switch (response.statusCode) {
      case 200:
        var utf8Decode = utf8.decode(response.bodyBytes);
        var responseJson = json.decode(utf8Decode);
        return responseJson;
        break;

      case 401:
        renewToken();
        break;

      default:
        throw FetchDataException('Lỗi kết nối: ${response.statusCode}');
    }
  }
}

extension NVNetwork on API {
  /// GET
  static Future<dynamic> getData({String uri}) async {
    final isOnline = await ApiMethod.hasNetwork();
    if (isOnline == false) {
      throw NetworkException();
    }

    logger.info('--uri: $uri');
    HttpClient client = HttpClient()
      ..badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);

    try {
      final request = await client.getUrl(Uri.parse(uri));
      final response = await request.close();

      String reply = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw FetchDataException('Lỗi kết nối: ${response.statusCode}');
      }

      return json.decode(reply);
    } catch (e) {
      logger.info(e.toString());
      throw FetchDataException('Lỗi kết nối');
    }
  }
}