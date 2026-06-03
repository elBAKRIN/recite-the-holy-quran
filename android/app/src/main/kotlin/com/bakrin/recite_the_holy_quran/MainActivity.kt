package com.bakrin.recite_the_holy_quran

import android.graphics.Color
import android.os.Bundle
import androidx.core.view.WindowCompat
import com.ryanheise.audioservice.AudioServiceActivity

// ترث AudioServiceActivity (بدل FlutterActivity) كما تتطلّب audio_service، كي
// تشترك الواجهة ومعالِج الصوت في محرّك Flutter نفسه؛ وإلا يحدث تعارض في تسجيل
// الإضافات فيفقد flutter_local_notifications سياقَ الـ Activity (NPE).
class MainActivity: AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
    }
}
