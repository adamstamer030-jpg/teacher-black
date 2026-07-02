package com.tutormanager.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity مطلوب (بدل FlutterActivity) لكي تعمل مكتبة local_auth 2.x
// بشكل صحيح على Android. استخدام FlutterActivity العادية يسبب crash فوري.
class MainActivity : FlutterFragmentActivity()
