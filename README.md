# MBBS III Attendance Tracker

A standalone, mobile-friendly attendance tracker for Phase 3, III MBBS Part I. The original attendance calculation engine and screens are retained; the account layer is adapted for Supabase Auth and per-user cloud sync.

## Features retained

- Dashboard, daily logging, subject-wise attendance, timetable/calendar and settings
- Hours-weighted attendance, attendance projections, safe-skip calculations
- Holiday/cancellation events, clinical posting rotation settings and manual corrections
- JSON backup/restore and CSV exports
- Browser-local fallback when cloud settings have not been configured
- Email/password login and private per-user cloud state when Supabase is configured

## Deploy

1. In the existing Supabase project, open **SQL Editor** and run `supabase/migrations/202610140001_attendance_tracker_state.sql`. This creates only `attendance_tracker_state` and its save RPC; it does not modify the existing study-tracker tables.
2. In Supabase project settings, copy the **publishable key** (or legacy `anon` public key). Never use a `service_role` key in browser code.
3. Replace `PASTE_YOUR_SUPABASE_ANON_KEY_HERE` in `index.html` with that publishable/anon key.
4. In Supabase Authentication settings, configure the site URL and redirect URLs for your Netlify site. Decide whether email confirmation should be required.
5. In Netlify, choose **Add new site → Import an existing project**, connect GitHub, choose this repository, and deploy with no build command and publish directory `.`. Future pushes to `main` will redeploy automatically.

## Data and security

`attendance_tracker_state.user_id` references `auth.users`. Row-level security restricts reads to `auth.uid()`; cloud writes use a revision-checked RPC so devices do not silently overwrite each other. The Supabase browser key is public by design; RLS—not secrecy of the key—protects user data. Never put a service-role key in `index.html`.

Each user has their own full attendance state in one row, preserving the existing app's data model. If a revision conflict is detected, the app pauses and offers loading the latest cloud copy or explicitly overwriting it from the current device. Use the in-app JSON export as an additional backup.

## Local testing

Open `index.html` in a browser. Until the Supabase key and SQL migration are configured, it uses local browser storage. To test cloud sync, deploy over HTTPS, create an account, record a test attendance status, refresh, and then sign in on another device using the same email.
