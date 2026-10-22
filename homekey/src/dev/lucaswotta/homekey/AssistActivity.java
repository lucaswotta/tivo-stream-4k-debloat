package dev.lucaswotta.homekey;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;

/**
 * Answers the Assistant button. Android handles that key before the accessibility key filter, so no
 * service can take it, but it does send ACTION_ASSIST to whatever is set as the assistant. This opens
 * the Play Store instead of a voice assistant.
 */
public class AssistActivity extends Activity {
    private static final ComponentName PLAY_STORE =
            new ComponentName("com.android.vending", "com.google.android.finsky.tvmainactivity.TvMainActivity");

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        try {
            startActivity(new Intent(Intent.ACTION_MAIN)
                    .setComponent(PLAY_STORE)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        } catch (ActivityNotFoundException missing) {
            // Play Store removed or disabled: nothing to open.
        }
        finish();
    }
}
