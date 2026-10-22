package dev.lucaswotta.homekey;

import android.accessibilityservice.AccessibilityService;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;

/**
 * Sends the remote's Home key to the launcher. The stock launcher declares HOME with priority 2 and
 * Android picks the highest priority before it looks at the user's choice, so set-home-activity has no
 * effect on this firmware, and the NES core service uninstalls any other app that declares HOME. So the
 * launcher (patched, see launcher/) does not declare it and this service opens it by component.
 * When the launcher is not installed the key passes through to the stock one.
 *
 * Enable over adb (scripts/install-launcher.sh does it):
 *   settings put secure enabled_accessibility_services dev.lucaswotta.homekey/.HomeKeyService
 *   settings put secure accessibility_enabled 1
 */
public class HomeKeyService extends AccessibilityService {
    private static final ComponentName LAUNCHER = new ComponentName("com.gathin.tvhome", "com.gathin.tvhome.MainActivity");

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        // Android starts the stock launcher at boot; take Home from it as soon as this service is bound.
        openLauncher();
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (event.getKeyCode() != KeyEvent.KEYCODE_HOME) return false;
        if (event.getAction() == KeyEvent.ACTION_UP && !event.isCanceled()) return openLauncher();
        return true;
    }

    private boolean openLauncher() {
        try {
            startActivity(new Intent(Intent.ACTION_MAIN)
                    .setComponent(LAUNCHER)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED));
            return true;
        } catch (ActivityNotFoundException missing) {
            return false;
        }
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
    }

    @Override
    public void onInterrupt() {
    }
}
