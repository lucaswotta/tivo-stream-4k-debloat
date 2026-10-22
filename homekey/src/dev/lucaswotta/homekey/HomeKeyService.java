package dev.lucaswotta.homelite;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;

/**
 * Sends the remote's Home key to this launcher. The stock launcher declares HOME with priority 2 and
 * Android picks the highest priority before it looks at the user's choice, so set-home-activity has no
 * effect on this firmware, and the NES core service uninstalls any other app that declares HOME. So the
 * launcher does not declare it and this service opens it by component. Other keys pass through untouched.
 *
 * Enable over adb (scripts/install-launcher.sh does it):
 *   settings put secure enabled_accessibility_services dev.lucaswotta.homelite/.HomeKeyService
 *   settings put secure accessibility_enabled 1
 */
public class HomeKeyService extends AccessibilityService {

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        // Android starts the stock launcher at boot; take Home from it as soon as this service is bound.
        openHome();
    }

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (event.getKeyCode() != KeyEvent.KEYCODE_HOME) return false;
        if (event.getAction() == KeyEvent.ACTION_UP && !event.isCanceled()) openHome();
        return true;
    }

    private void openHome() {
        startActivity(new Intent(this, MainActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED));
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
    }

    @Override
    public void onInterrupt() {
    }
}
