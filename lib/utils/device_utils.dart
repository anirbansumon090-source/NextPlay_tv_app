import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  static Future<String> getUniqueId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceRawInfo = "";

    // ১. ডিভাইস ইনফো গেট করা হচ্ছে
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // ব্র্যান্ড, মডেল, এবং আইডি দিয়ে ইউনিক স্ট্রিং তৈরি
      deviceRawInfo = "${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceRawInfo = "${iosInfo.name}-${iosInfo.model}-${iosInfo.identifierForVendor}";
    }

    // ২. Base64 কনভার্ট
    String base64String = base64Encode(utf8.encode(deviceRawInfo));
    
    // ৩. MD5 হ্যাশ এবং আপারকেস
    var bytes = utf8.encode(base64String);
    var digest = md5.convert(bytes);
    
    return digest.toString().toUpperCase();
  }
}
