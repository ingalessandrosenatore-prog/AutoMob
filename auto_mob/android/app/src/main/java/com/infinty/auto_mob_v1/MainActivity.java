package com.infinty.auto_mob_v1;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Android 8+ raggruppa le notifiche in canali configurabili dall'utente.
        // L'id deve coincidere con quello inviato dalla Edge Function.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                "automob_reminders",
                "Promemoria AutoMob",
                NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription("Scadenze, manutenzione e aggiornamento chilometri");

            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }
}
