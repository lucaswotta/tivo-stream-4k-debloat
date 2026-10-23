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
 * The commands are fixed at build time in Profile.COMMANDS, generated from bootclean/profile/*.txt.
 */
public class CleanJob extends JobService {
    private static final String TAG = "bootclean";

    @Override
    public boolean onStartJob(final JobParameters params) {
        new Thread(() -> {
            try (Adb adb = Adb.connect(this, 60_000)) {
                for (String command : Profile.COMMANDS) adb.shell(command);
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
