package dev.lucaswotta.bootclean;

import android.app.job.JobParameters;
import android.app.job.JobService;
import android.util.Log;

import java.io.IOException;

/**
 * Stops the processes that a suspended package still gets at boot (scripts/post-boot.sh keeps the same
 * list for a computer). Suspending, appops and killBackgroundProcesses do not stop them; a force-stop
 * from the shell does, and the TV's own adbd is the only shell an app can reach.
 *
 * Android fills the Assistant settings back in with Katniss at every boot, and as long as it is the
 * registered Assistant the system keeps its interactor process alive. The Assistant button goes to
 * homekey's AssistActivity (opens the Play Store) and the voice interaction service is cleared.
 */
public class CleanJob extends JobService {
    private static final String TAG = "bootclean";
    private static final String[] STOP = {
        "com.nes.coreservice",
        "com.tivo.sageservice",
        "com.google.android.tvlauncher",
        "com.google.android.katniss",
        "com.nes.tvbugtracker",
        // Its notification listener is switched off (cmd notification disallow_listener, which survives a
        // reboot), so nothing holds it after a force-stop except a content provider query at boot.
        "com.google.android.tvrecommendations",
    };

    private static final String[] COMMANDS = {
        "settings put secure assistant dev.lucaswotta.homekey/.AssistActivity",
        "settings put secure voice_interaction_service ''",
    };

    @Override
    public boolean onStartJob(final JobParameters params) {
        new Thread(() -> {
            try (Adb adb = Adb.connect(this, 60_000)) {
                for (String command : COMMANDS) adb.shell(command);
                for (String pkg : STOP) adb.shell("am force-stop " + pkg);
            } catch (IOException e) {
                Log.w(TAG, "cleanup skipped: " + e.getMessage());
            } finally {
                jobFinished(params, false);
            }
        }).start();
        return true;
    }

    @Override
    public boolean onStopJob(JobParameters params) {
        return false;
    }
}
