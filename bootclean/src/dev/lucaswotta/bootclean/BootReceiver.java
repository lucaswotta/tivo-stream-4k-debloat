package dev.lucaswotta.bootclean;

import android.app.job.JobInfo;
import android.app.job.JobScheduler;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

/**
 * Schedules the cleanup a minute or so after boot, when the services it stops have come up, and again
 * later for the ones that start late. A manual RUN starts it at once.
 */
public class BootReceiver extends BroadcastReceiver {
    private static final long[] AFTER_BOOT_MS = {60_000, 150_000, 300_000};
    private static final long[] MANUAL_MS = {0, 120_000};

    @Override
    public void onReceive(Context context, Intent intent) {
        long[] delays = "dev.lucaswotta.bootclean.RUN".equals(intent.getAction()) ? MANUAL_MS : AFTER_BOOT_MS;
        JobScheduler scheduler = context.getSystemService(JobScheduler.class);
        for (int i = 0; i < delays.length; i++) {
            scheduler.schedule(new JobInfo.Builder(i, new ComponentName(context, CleanJob.class))
                    .setMinimumLatency(delays[i])
                    .setOverrideDeadline(delays[i] + 30_000)
                    .build());
        }
    }
}
