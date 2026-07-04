// lib/data/services/device_mode_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class DeviceModeService {
  const DeviceModeService();

  // MainActivity.kt এর সাথে যোগাযোগের জন্য মেথড চ্যানেল নাম
  // (নিশ্চিত করুন আপনার MainActivity এর CHANNEL স্ট্রিংও হুবহু এটাই আছে)
  static const MethodChannel _channel = MethodChannel('com.ottking.app/device_info');

  /// ডিভাইসটি Smart TV / Fire TV নাকি Mobile তা ডিটেক্ট করে।
  /// [context] পাস করতে হবে যেন নেটিভ চেক ফেইল করলে স্ক্রিন সাইজ দেখে ব্যাকআপ লজিক কাজ করতে পারে।
  Future<bool> isSmartTv(BuildContext context) async {
    // ওয়েব প্ল্যাটফর্ম হলে টিভি ডিটেকশন ফলস হবে
    if (kIsWeb) return false;
    
    // শুধুমাত্র অ্যান্ড্রয়েড ও ফায়ার ওএস প্ল্যাটফর্মের জন্য রান করবে
    if (Platform.isAndroid) {
      try {
        // ১. প্রথম চেষ্টা: নেটিভ অ্যান্ড্রয়েড (UiModeManager / Leanback) চেক
        final bool? isTvNative = await _channel.invokeMethod<bool>('isAndroidTV');
        if (isTvNative == true) {
          return true;
        }
      } catch (e) {
        debugPrint("Native TV check failed, switching to fallback layout check: $e");
      }

      // ── ২. দ্বিতীয় চেষ্টা: কাস্টম/লোকাল টিভি বক্স বা চায়না টিভি ফিক্স (Fallback Logic) ──
      // অনেক সস্তা টিভি নিজেদের মোবাইল ওএস হিসেবে রিপোর্ট করে। তাই আমরা স্ক্রিনের ফিজিক্যাল ডাইমেনশন দেখব।
      try {
        final Size size = MediaQuery.of(context).size;
        final double width = size.width;
        final double height = size.height;
        
        // টিভি সবসময় ল্যান্ডস্কেপ মোডে থাকে (উইডথ হাইটের চেয়ে বড়)
        final bool isLandscape = width > height;
        
        // স্ট্যান্ডার্ড টিভির মিনিমাম উইডথ সাধারণত ৯৬০ ডিপি (dp) বা তার বেশি হয়
        // এবং অ্যাসপেক্ট রেশিও (Width/Height) ১.৫ এর বেশি হয় (যেমন ১৬:৯)
        if (isLandscape && width >= 960 && (width / height) >= 1.5) {
          return true; 
        }
      } catch (e) {
        debugPrint("Screen size measurement failed: $e");
      }
    }
    
    // কোনো কন্ডিশন ম্যাচ না করলে ডিফল্ট মোবাইল হিসেবে গণ্য হবে
    return false;
  }

  /// ডিভাইসের টাইপ অনুযায়ী স্ট্রিং লেবেল রিটার্ন করে (ডিবাগিং বা ইউআই তে দেখানোর জন্য)
  String getDeviceLabel(bool isTv) => isTv ? 'Smart TV' : 'Mobile';
}
