package dev.lucaswotta.homelite;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.StateListDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.LruCache;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextClock;
import android.widget.TextView;

import java.text.Collator;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity
        implements View.OnClickListener, View.OnFocusChangeListener {
    private static final int BG = 0xFF101216;
    private static final int COLUMNS = 5;

    // Inner classes are static on purpose: javac 17 writes a nameless MethodParameters entry for the
    // outer-instance parameter of non-static ones, and the d8 in build-tools 34 crashes on it.
    private static final class Entry {
        final String label;
        final Intent launch;
        final ResolveInfo info;

        Entry(String label, Intent launch, ResolveInfo info) {
            this.label = label;
            this.launch = launch;
            this.info = info;
        }
    }

    private final List<Entry> entries = new ArrayList<>();
    private final LruCache<String, Drawable> artwork = new LruCache<>(40);
    private final ExecutorService loader = Executors.newFixedThreadPool(2);
    private final Handler main = new Handler(Looper.getMainLooper());
    private GridView grid;
    private Adapter adapter;
    private int tileWidth;
    private int tileHeight;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setBackgroundDrawable(new ColorDrawable(BG));

        int pad = dp(48);
        int gap = dp(20);
        tileWidth = (getResources().getDisplayMetrics().widthPixels - 2 * pad - (COLUMNS - 1) * gap) / COLUMNS;
        tileHeight = tileWidth * 9 / 16;

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(pad, dp(32), pad, 0);

        TextClock clock = new TextClock(this);
        clock.setFormat24Hour("HH:mm");
        clock.setFormat12Hour("HH:mm");
        clock.setTextColor(Color.WHITE);
        clock.setTextSize(40);
        TextClock date = new TextClock(this);
        date.setFormat24Hour("EEEE, d 'de' MMMM");
        date.setFormat12Hour("EEEE, d 'de' MMMM");
        date.setTextColor(0xFFA0A6B0);
        date.setTextSize(18);
        root.addView(clock);
        root.addView(date);

        grid = new GridView(this);
        grid.setNumColumns(COLUMNS);
        grid.setHorizontalSpacing(gap);
        grid.setVerticalSpacing(gap);
        grid.setClipChildren(false);
        grid.setClipToPadding(false);
        grid.setPadding(0, dp(28), 0, dp(32));
        grid.setSelector(new ColorDrawable(Color.TRANSPARENT));
        grid.setVerticalScrollBarEnabled(false);
        adapter = new Adapter(this);
        grid.setAdapter(adapter);
        root.addView(grid, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        setContentView(root);
    }

    @Override
    protected void onStart() {
        super.onStart();
        reload();
        focusFirstTile();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        if (grid != null) {
            grid.setSelection(0);
            focusFirstTile();
        }
    }

    private void focusFirstTile() {
        grid.post(new FocusFirst(grid));
    }

    private static final class FocusFirst implements Runnable {
        private final GridView grid;

        FocusFirst(GridView grid) {
            this.grid = grid;
        }

        @Override
        public void run() {
            View first = grid.getChildAt(0);
            if (first != null && grid.findFocus() == null) first.requestFocus();
        }
    }

    @Override
    public void onBackPressed() {
        // A home screen has nowhere to go back to.
    }

    @Override
    protected void onDestroy() {
        loader.shutdownNow();
        super.onDestroy();
    }

    private void reload() {
        PackageManager pm = getPackageManager();
        Intent query = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);
        // A TreeMap sorts with the platform Collator and keeps duplicate labels apart; a Comparator of our
        // own would add a bridge method that d8 8.2 also trips over (see Entry).
        Map<String, Entry> sorted = new TreeMap<>(Collator.getInstance());
        for (ResolveInfo ri : pm.queryIntentActivities(query, 0)) {
            if (ri.activityInfo.packageName.equals(getPackageName())) continue;
            Intent launch = new Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER)
                    .setComponent(new ComponentName(ri.activityInfo.packageName, ri.activityInfo.name))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
            String label = String.valueOf(ri.loadLabel(pm));
            sorted.put(label + '\u0000' + ri.activityInfo.packageName, new Entry(label, launch, ri));
        }
        List<Entry> fresh = new ArrayList<>(sorted.values());
        fresh.add(new Entry("Configurações",
                new Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK), null));

        if (sameEntries(fresh)) return;
        entries.clear();
        entries.addAll(fresh);
        artwork.evictAll();
        adapter.notifyDataSetChanged();
    }

    private boolean sameEntries(List<Entry> fresh) {
        if (fresh.size() != entries.size()) return false;
        for (int i = 0; i < fresh.size(); i++) {
            if (!fresh.get(i).launch.filterEquals(entries.get(i).launch)
                    || !fresh.get(i).label.equals(entries.get(i).label)) return false;
        }
        return true;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private Drawable tileBackground() {
        GradientDrawable idle = new GradientDrawable();
        idle.setColor(0xFF1B1F27);
        idle.setCornerRadius(dp(10));
        GradientDrawable focused = new GradientDrawable();
        focused.setColor(0xFF2A303C);
        focused.setCornerRadius(dp(10));
        focused.setStroke(dp(3), Color.WHITE);
        StateListDrawable states = new StateListDrawable();
        states.addState(new int[]{android.R.attr.state_focused}, focused);
        states.addState(new int[]{}, idle);
        return states;
    }

    private static final class Adapter extends BaseAdapter {
        private final MainActivity a;

        Adapter(MainActivity activity) {
            this.a = activity;
        }

        @Override public int getCount() { return a.entries.size(); }
        @Override public Object getItem(int position) { return a.entries.get(position); }
        @Override public long getItemId(int position) { return position; }

        @Override
        public View getView(int position, View convert, ViewGroup parent) {
            LinearLayout tile = convert == null ? a.newTile() : (LinearLayout) convert;
            Entry entry = a.entries.get(position);
            ((TextView) tile.getChildAt(1)).setText(entry.label);
            tile.setTag(entry);
            a.bindArtwork((ImageView) tile.getChildAt(0), entry);
            return tile;
        }
    }

    private LinearLayout newTile() {
        LinearLayout tile = new LinearLayout(this);
        tile.setOrientation(LinearLayout.VERTICAL);
        tile.setFocusable(true);
        tile.setBackground(tileBackground());
        tile.setPadding(dp(6), dp(6), dp(6), dp(6));
        tile.setOnClickListener(this);
        tile.setOnFocusChangeListener(this);
        ImageView image = new ImageView(this);
        image.setScaleType(ImageView.ScaleType.FIT_CENTER);
        tile.addView(image, new LinearLayout.LayoutParams(tileWidth - dp(12), tileHeight));
        TextView name = new TextView(this);
        name.setTextColor(Color.WHITE);
        name.setTextSize(15);
        name.setSingleLine(true);
        name.setGravity(Gravity.CENTER);
        name.setPadding(0, dp(6), 0, dp(4));
        tile.addView(name, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        return tile;
    }

    @Override
    public void onClick(View tile) {
        startActivity(((Entry) tile.getTag()).launch);
    }

    @Override
    public void onFocusChange(View tile, boolean focused) {
        float scale = focused ? 1.06f : 1f;
        tile.animate().scaleX(scale).scaleY(scale).setDuration(100).start();
    }

    private void bindArtwork(ImageView image, Entry entry) {
        String key = entry.label;
        image.setTag(key);
        Drawable cached = artwork.get(key);
        if (cached != null) {
            image.setImageDrawable(cached);
            return;
        }
        image.setImageDrawable(null);
        if (entry.info == null) return;
        loader.execute(new ArtworkTask(this, image, entry, key));
    }

    private static final class ArtworkTask implements Runnable {
        private final MainActivity a;
        private final ImageView image;
        private final Entry entry;
        private final String key;
        private Drawable loaded;

        ArtworkTask(MainActivity activity, ImageView image, Entry entry, String key) {
            this.a = activity;
            this.image = image;
            this.entry = entry;
            this.key = key;
        }

        @Override
        public void run() {
            if (loaded == null) {
                PackageManager pm = a.getPackageManager();
                loaded = entry.info.activityInfo.loadBanner(pm);
                if (loaded == null) loaded = entry.info.loadIcon(pm);
                a.main.post(this);
                return;
            }
            a.artwork.put(key, loaded);
            if (key.equals(image.getTag())) image.setImageDrawable(loaded);
        }
    }
}
