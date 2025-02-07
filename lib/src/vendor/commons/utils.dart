import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nukeviet/src/include/constants.dart';
import 'package:nukeviet/src/include/router.dart';
import 'package:nukeviet/src/vendor/components/gradient_view.dart';
import 'package:nukeviet/src/vendor/network/response/mapping/nv_token.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart';

/// LOGGER
final SimpleLogger logger = SimpleLogger()
  ..mode = LoggerMode.print
  ..setLevel(Level.FINEST, includeCallerInfo: true);

extension EmailValidator on String {
  bool get isValidEmail => GetUtils.isEmail(this);
}

class Utils {
  static hideKeyboard() => FocusManager.instance.primaryFocus.unfocus();

  static PreferredSize gradientAppBar({Widget child, double height}) {
    return PreferredSize(
      preferredSize: Size.fromHeight(height ?? AppBar().preferredSize.height),
      child: GradientView(child: child),
    );
  }

  static Future<void> revokeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(AppConstant.accessToken);
    prefs.remove(AppConstant.userId);
    prefs.remove(AppConstant.username);
    prefs.remove(AppConstant.password);
  }

  static Future<String> getAppToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String accessToken = prefs.getString(AppConstant.accessToken) ?? '';
    return accessToken;
  }

  static Future<int> getUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstant.userId);
  }

  static Future<void> saveToken(NVToken token) async {
    logger.info(token.expiresIn);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(AppConstant.accessToken, token.accessToken);
    prefs.setInt(AppConstant.userId, token.userId);
  }

  static Future<void> saveString(String value, String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  static Future<String> getLoginParam() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(AppConstant.username);
    final token = prefs.getString(AppConstant.accessToken);
    return '$u:$token';
  }

  static Future<String> getString(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static void logout() {
    revokeToken();
    Get.offAllNamed(GetRouter.login);
  }

  static Widget getSvgItem(String path,
      {double width, double height, Color color}) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(path, color: color),
    );
  }

  static void showAwesomeDialog(
      BuildContext context, {
        String title = r'Xác nhận',
        String message = '',
        Widget child,
        String okTitle = r'Đồng ý',
        String cancelTitle = 'Bỏ qua',
        bool showCancelButton = true,
        bool isDestructive = false,
        Function onPressedOK,
        Function onPressCancel,
        bool dismissOnTouchOutside = false,
      }) {
    AwesomeDialog(
      context: context,
      dismissOnTouchOutside: dismissOnTouchOutside,
      animType: AnimType.SCALE,
      dialogType: DialogType.NO_HEADER,
      title: title,
      desc: message,
      btnOkOnPress: onPressedOK,
      btnOkText: okTitle,
      btnOkColor: isDestructive ? Colors.deepOrange : Colors.grey[300],
      btnCancel: showCancelButton
          ? AnimatedButton(
        isFixedHeight: false,
        pressEvent: () {
          Navigator.pop(context);
          if (onPressCancel != null) {
            onPressCancel();
          }
        },
        text: cancelTitle,
        color: Colors.grey[300],
        buttonTextStyle: TextStyle(
          color: Colors.black87,
        ),
      )
          : null,
    )..show();
  }

  //
  static Widget emptyDataWidget({String text = r'Chưa có dữ liệu'}) {
    return Column(
      children: <Widget>[
        SizedBox(height: 64),
        Center(
          child: Text(
            '$text',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.normal,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        )
      ],
    );
  }

  static String dateTimeNow() {
    var now = DateTime.now();
    var minute = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
    return '${now.day}/${now.month}/${now.year} ${now.hour}:$minute';
  }

  static Widget completeRefreshWidget = Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      const Icon(
        Icons.done,
        color: Colors.grey,
      ),
      Container(
        width: 10.0,
      ),
      Text(
        r'Cập nhật lúc ' + dateTimeNow(),
        style: GoogleFonts.openSans(
          color: Colors.grey,
        ),
      )
    ],
  );
}

extension DateUtil on Utils {
  static DateTime convertStringToDateTime({String dateInString, String format}) {
    DateFormat dateFormat = DateFormat(format);
    try {
      final date = dateFormat.parse(dateInString);
      return date;
    } catch (e) {
      logger.info(e.toString());
      return null;
    }
  }
}