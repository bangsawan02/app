// MainActivity.java
package com.floating;

import androidx.appcompat.app.AppCompatActivity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

public class MainActivity extends AppCompatActivity {

    private static final int CODE_DRAW_OVER_OTHER_APP_PERMISSION = 2084;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main); // Sesuaikan dengan layout utamamu

        // Periksa apakah izin sudah diberikan
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            // Jika belum, minta izin
            requestPermission();
        } else {
            // Jika sudah, langsung mulai service
            startFloatingService();
        }
    }

    private void requestPermission() {
        Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + getPackageName()));
        startActivityForResult(intent, CODE_DRAW_OVER_OTHER_APP_PERMISSION);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == CODE_DRAW_OVER_OTHER_APP_PERMISSION) {
            // Periksa hasil izin
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this)) {
                // Izin diberikan
                startFloatingService();
            } else {
                // Izin ditolak
                Toast.makeText(this, "Izin Teks Mengambang Ditolak. Aplikasi tidak dapat berfungsi.", Toast.LENGTH_SHORT).show();
            }
        } else {
            super.onActivityResult(requestCode, resultCode, data);
        }
    }

    private void startFloatingService() {
        // Mulai FloatingTextService
        startService(new Intent(this, FloatingTextService.class));
        finish(); // Tutup MainActivity setelah Service dimulai (opsional)
    }
}