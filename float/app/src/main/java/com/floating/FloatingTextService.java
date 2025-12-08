// FloatingTextService.java
package com.floating;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.PixelFormat;
import android.os.BatteryManager;
import android.os.Build;
import android.os.IBinder;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;
import androidx.core.app.NotificationCompat;
import java.util.Locale;

public class FloatingTextService extends Service {

    private WindowManager mWindowManager;
    private View mFloatingView;
    private TextView mBatteryInfoTextView;
    private BroadcastReceiver mBatteryReceiver;

    // Variabel untuk Dragging
    private int initialX;
    private int initialY;
    private float initialTouchX;
    private float initialTouchY;
    
    private static final String CHANNEL_ID = "FloatingTextServiceChannel";
    private static final int NOTIFICATION_ID = 101;
    private final int MAX_CLICK_DURATION = 200; // Durasi untuk dianggap sebagai klik

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        // 1. Inisialisasi Foreground Service
        createNotificationChannel();
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Informasi Baterai Mengambang")
                .setContentText("Aplikasi menampilkan status baterai.")
                .setSmallIcon(R.drawable.ic_launcher_foreground) // Ganti dengan ikon aplikasimu
                .build();
        startForeground(NOTIFICATION_ID, notification);

        // 2. Inisialisasi Window Manager dan Tampilan Mengambang
        mWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        LayoutInflater inflater = (LayoutInflater) getSystemService(LAYOUT_INFLATER_SERVICE);
        mFloatingView = inflater.inflate(R.layout.floating_layout, null);
        mBatteryInfoTextView = mFloatingView.findViewById(R.id.battery_info_text);

        // 3. Atur Parameter Layout
        int LAYOUT_FLAG;
        // Gunakan TYPE_APPLICATION_OVERLAY untuk Android O (API 26) ke atas
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            LAYOUT_FLAG = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            // Gunakan TYPE_PHONE untuk versi Android yang lebih lama
            LAYOUT_FLAG = WindowManager.LayoutParams.TYPE_PHONE;
        }

        final WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                LAYOUT_FLAG,
                // FLAG_NOT_FOCUSABLE dan FLAG_NOT_TOUCH_MODAL agar tidak memblokir sentuhan di aplikasi lain
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        | WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                        | WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
                PixelFormat.TRANSLUCENT);

        // 4. Tambahkan Tampilan ke Window Manager
        try {
            mWindowManager.addView(mFloatingView, params);
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 5. Implementasi OnTouchListener untuk Dragging
        mFloatingView.setOnTouchListener(new View.OnTouchListener() {
            private long lastClickTime = 0;

            @Override
            public boolean onTouch(View v, MotionEvent event) {
                WindowManager.LayoutParams currentParams = (WindowManager.LayoutParams) mFloatingView.getLayoutParams();

                switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                        lastClickTime = System.currentTimeMillis();
                        
                        // Simpan posisi awal view dan posisi sentuhan
                        initialX = currentParams.x;
                        initialY = currentParams.y;
                        initialTouchX = event.getRawX();
                        initialTouchY = event.getRawY();
                        return true;

                    case MotionEvent.ACTION_MOVE:
                        // Hitung perubahan posisi (delta)
                        int deltaX = (int) (event.getRawX() - initialTouchX);
                        int deltaY = (int) (event.getRawY() - initialTouchY);

                        // Perbarui posisi view
                        currentParams.x = initialX + deltaX;
                        currentParams.y = initialY + deltaY;

                        // Update view di layar
                        mWindowManager.updateViewLayout(mFloatingView, currentParams);
                        return true;

                    case MotionEvent.ACTION_UP:
                        // Logika untuk mendeteksi klik (misal, untuk menyembunyikan/menampilkan)
                        if (System.currentTimeMillis() - lastClickTime < MAX_CLICK_DURATION &&
                            (Math.abs(event.getRawX() - initialTouchX) < 10 &&
                             Math.abs(event.getRawY() - initialTouchY) < 10)) {
                            
                            // Contoh: Toggle visibilitas saat diklik
                            // mFloatingView.setVisibility(mFloatingView.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
                        }
                        return true;
                }
                return false;
            }
        });
        
        // 6. Daftarkan Broadcast Receiver untuk Status Baterai
        mBatteryReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (Intent.ACTION_BATTERY_CHANGED.equals(intent.getAction())) {
                    updateBatteryInfo(intent);
                }
            }
        };
        IntentFilter filter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
        registerReceiver(mBatteryReceiver, filter);
        
        // Panggil update pertama kali
        Intent batteryIntent = getApplicationContext().registerReceiver(null, filter);
        if (batteryIntent != null) {
            updateBatteryInfo(batteryIntent);
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Floating Service Channel",
                    NotificationManager.IMPORTANCE_DEFAULT
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
            }
        }
    }

    private void updateBatteryInfo(Intent intent) {
        // Dapatkan data utama
        int level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
        int status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
        int temperature = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0);
        int voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0);
        int plug = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1);
        
        // Dapatkan data Arus (Memerlukan API 21/Lollipop ke atas)
        BatteryManager bm = (BatteryManager) getSystemService(BATTERY_SERVICE);
        long currentNow = 0; // dalam microampere
        if (bm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            currentNow = bm.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW); 
        }
        
        // Hitung dan Konversi
        float percent = level * 100 / (float) scale;
        float tempC = temperature / 10f;
        float voltageV = voltage / 1000f; // mV ke V
        
        // Arus dalam mA dan Daya dalam Watt
        float currentMa = currentNow / 1000f; 
        float powerW = Math.abs(voltageV * (currentMa / 1000f)); 
        
        // Status Pengisian Daya
        String statusText;
        boolean isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL;
        
        if (isCharging) {
             switch (plug) {
                 case BatteryManager.BATTERY_PLUGGED_AC:
                     statusText = "Mengisi (AC)";
                     break;
                 case BatteryManager.BATTERY_PLUGGED_USB:
                     statusText = "Mengisi (USB)";
                     break;
                 case BatteryManager.BATTERY_PLUGGED_WIRELESS:
                     statusText = "Mengisi (Nirkabel)";
                     break;
                 default:
                     statusText = "Mengisi Daya";
                     break;
             }
        } else if (status == BatteryManager.BATTERY_STATUS_FULL) {
            statusText = "Penuh";
        } else {
            statusText = "Tidak Mengisi";
        }

        // Format Teks Sesuai Contoh Gambar
        String infoText = String.format(Locale.getDefault(),
                "%.0f%% • %s\n" +
                "⚡ %.0fmA • %.1fW • %.1fV • %.1f°C",
                percent,
                statusText,
                currentMa,
                powerW,
                voltageV,
                tempC
        );

        mBatteryInfoTextView.setText(infoText);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        // Bersihkan view dan receiver saat Service dihentikan
        if (mFloatingView != null) {
            mWindowManager.removeView(mFloatingView);
        }
        if (mBatteryReceiver != null) {
            unregisterReceiver(mBatteryReceiver);
        }
        stopForeground(true);
    }
}