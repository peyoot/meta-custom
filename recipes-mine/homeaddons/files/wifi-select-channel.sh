#!/bin/sh
# wifi-select-channel.sh
#
# Software (userspace) ACS replacement for Murata/Infineon CYW55xx Wi-Fi
# modules on Digi ConnectCore MP255, where the firmware does not implement
# the nl80211 "survey" API that hostapd's built-in ACS relies on.
#
# Strategy:
#   1. Try to get scan / channel-quality data from the Cypress "wl" tool
#      (wl scanresults, and optionally wl chanim_stats if your firmware
#      supports the channel-interference monitor).
#   2. If "wl" is unavailable, unsupported, or returns nothing usable,
#      fall back to a plain "iw dev <ifc> scan" (nl80211), which every
#      brcmfmac-based build supports for STA-side scanning even when it
#      does not support AP-side survey data for hostapd's ACS.
#   3. Score every legal channel (fewer/weaker neighboring BSSes = better,
#      2.4GHz gets an extra bonus for the non-overlapping set 1/6/11,
#      5GHz DFS channels can be excluded by policy).
#   4. Write the winning channel into a hostapd config file.
#
# IMPORTANT - READ BEFORE USE
#   "wl scanresults" / "wl chanim_stats" output format is NOT standardized
#   across wl builds/firmware. The parsing below matches the common
#   Broadcom/Cypress wl text-report layout, but you MUST verify it against
#   the actual output on your board (run the commands manually first: see
#   the "wl_probe" function) and adjust the awk/sed patterns if needed.
#   This script is a starting point for your own validation - it has not
#   been tested on real MP255 hardware and must be reviewed/qualified by
#   your team (per Digi's internal AI-use policy) before it goes into any
#   product image.
#
# Usage:
#   wifi-select-channel.sh -i wlan1 -s wlan0 -b 2.4 -c /etc/hostapd_wlan1.conf
#   wifi-select-channel.sh -i wlan1 -s wlan0 -b 5   -c /etc/hostapd_wlan1.conf --no-dfs
#
# Exit codes: 0 = channel written OK, 1 = usage error, 2 = no scan data at all

set -u

# ----------------------------------------------------------------------
# Defaults (override with flags)
# ----------------------------------------------------------------------
AP_IFACE="wlan1"          # interface hostapd will run the AP on. Defaults
                          # to wlan1 if -i/--ap-iface isn't passed (matches
                          # every real-hardware test in this project so
                          # far); override with -i for any other interface
                          # name. AP_IFACE_EXPLICIT tracks whether this
                          # came from an actual flag vs. the default, so
                          # the log can say which happened.
AP_IFACE_EXPLICIT=0
SCAN_IFACE=""             # interface used to perform the scan. Optional: if
                          # left empty, preflight() auto-picks a sibling
                          # interface on the same radio (phy), e.g. wlan0.
HOSTAPD_CONF=""           # path to the hostapd config file to patch.
                          # Defaults to /etc/hostapd_<AP_IFACE>.conf if
                          # -c/--conf isn't passed (derived from whatever
                          # AP_IFACE ends up being - explicit -i or the
                          # wlan1 default - not a fixed string, so it
                          # still lines up correctly if you only override
                          # -i and not -c)
HOSTAPD_CONF_EXPLICIT=0
BAND="2.4"                # "2.4", "5" or "6" - only used as a fallback if
                          # not explicitly passed AND auto-detection from
                          # the target hostapd conf's hw_mode= (see below)
                          # doesn't find anything usable
BAND_EXPLICIT=0           # set to 1 by arg parsing if -b/--band was
                          # actually passed on the command line - lets us
                          # tell "user explicitly chose 2.4" apart from
                          # "nobody said anything, this is just the
                          # fallback default" so auto-detection knows
                          # whether it's allowed to override BAND
ALLOW_DFS=0               # DEFAULT OFF as of this real-hardware finding: on
                          # this board/firmware combo, DFS channels (e.g.
                          # 132) fail to start with hostapd's
                          # "brcmf_cfg80211_start_ap: SET SSID error (-52)"
                          # every single time - confirmed by switching to a
                          # non-DFS channel (36) and seeing hostapd come up
                          # cleanly with no further -52 in dmesg. Root cause
                          # looks like missing board-specific nvram/CLM
                          # calibration (falls back to a generic Cypress
                          # blob that likely lacks full DFS/radar data for
                          # this board) - flag this to Digi/Murata support.
                          # Pass --allow-dfs once that's resolved and
                          # you've confirmed DFS channels actually start.
HYSTERESIS_MARGIN_PCT=20  # Only switch away from the CURRENT channel
                          # (read from the conf before this run touches
                          # it) if the best-scored candidate's score is at
                          # least this many percent better (lower) than
                          # the current channel's own score in this same
                          # run's ranking. Added after real-hardware
                          # testing showed the channel picked could swing
                          # a lot between two runs a few seconds apart
                          # (likely chanim_stats reflecting only a short,
                          # freshly-reset sampling window right after
                          # preflight tears down and rebuilds the radio -
                          # see README) - without this, a run whose scan
                          # happened to catch a brief quiet/busy moment
                          # could bounce the AP to a different channel
                          # for no real long-term benefit, disconnecting
                          # clients on every run. 0 disables this (always
                          # switch to whatever scores best this run).
                          # Override with --switch-margin N.
SCAN_SETTLE_SECS=4        # time to let "wl scan" finish before reading results
SCAN_MAX_ATTEMPTS=4        # retry a failed scan this many times before
                          # giving up (see get_scan_wl comments further
                          # down: a failed scan is very likely racing
                          # against the driver's own internal periodic
                          # reconfig cycle, not a fixed-timing problem, so
                          # retrying is more robust than tuning a delay)
SCAN_RETRY_BACKOFF_SECS=2  # pause between failed scan attempts
STEP_SETTLE_SECS=2        # confirmed necessary on real hardware: pause this
                          # long after each state-changing preflight step
                          # (systemctl stop, ip link down, iw set type) -
                          # doing these back-to-back with no pause and then
                          # immediately scanning reliably reproduced
                          # "brcmf_cfg80211_scan: scan error (-52)"; adding
                          # a manual pause between steps (tested by hand
                          # with `sleep 10` before the scan) let it succeed
FINAL_SETTLE_SECS=5       # extra pause after the LAST preflight change
                          # (switching the AP vif off AP type, and bringing
                          # the scan interface up) before the first scan
                          # attempt - this is the step immediately before
                          # the scan that failed every time it ran with no
                          # pause
SYSTEMCTL_SETTLE_SECS=5   # pause after EVERY systemctl stop/start call in
                          # this script (wpa_supplicant, hostapd@<ap_iface>,
                          # plain hostapd.service, sibling hostapd@<sib>,
                          # and each service restarted in postflight()) -
                          # confirmed on real hardware that a shorter,
                          # step-specific value (2s) was not reliably
                          # enough, particularly for hostapd (which runs a
                          # full 802.11 state-machine teardown on stop,
                          # not just a process kill). Applying this
                          # uniformly to every systemctl operation instead
                          # of only some of them, per direct feedback.
LOCKFILE="/var/run/wifi-select-channel.lock"
LOGTAG="wifi-select-channel"

# Preflight behavior. Real hardware testing (ccmp25-dvk) showed that wlan0
# and wlan1 sit on the SAME phy (single-radio MCC design, confirmed via
# `iw dev` listing both under "phy#0"), and that scanning while hostapd is
# actively running on the sibling interface leaves the radio in a state
# where the next hostapd (re)start fails ("SET SSID error (-52)"). So by
# default this script stops anything that could contend for the radio
# before scanning, and restarts hostapd afterward if it stopped it.
DO_PREFLIGHT=1            # 1 = run preflight cleanup, 0 = skip (--no-preflight)
RESTART_HOSTAPD=1         # 1 = restart hostapd services this script stopped
RESTORE_NM=0              # 1 = re-enable NetworkManager management afterward
                          # (off by default: a sibling interface used only
                          # for scanning usually shouldn't be NM-managed
                          # anyway, and re-enabling it just re-creates the
                          # same contention risk for the next scheduled scan)
STOP_WPA_SUPPLICANT=1     # 1 = stop the global wpa_supplicant instance
                          # before scanning (see preflight() comments -
                          # confirmed on real hardware to hold wifi
                          # interfaces even when NetworkManager reports
                          # them "unmanaged", e.g. to provide the
                          # p2p-dev-wlan0 virtual device)
HOSTAPD_STOPPED=""        # space-separated list of systemd service names
                          # this script stopped, so it can restart just
                          # those in postflight() (hostapd@... services,
                          # and wpa_supplicant.service if applicable)
NM_UNMANAGED=""           # space-separated list of interfaces this script
                          # told NetworkManager to stop managing
AP_IFACE_WAS_UP=""        # "1" if the AP interface was administratively up
                          # before preflight brought it down

# Confirmed against real "wl chanim_stats" output on ccmp25-dvk (see
# samples/chanim_stats.txt): chanspec is a 16-bit field where
#   band    = chanspec & 0xC000   (0x0000=2.4GHz, 0xC000=5GHz, 0x8000=6GHz)
#   channel = chanspec & 0x00FF   (literal channel number, same for all bands)
ENABLE_CHANIM=1           # real hardware confirmed the format below; keep on
# Relative weight of the firmware's own airtime/interference measurement
# (chanim, "100 - idle% + obss-weight") vs. the neighbor-BSS penalty derived
# from wl/iw scan results. chanim is generally the more trustworthy signal
# since it reflects actually-measured channel occupancy rather than just
# counting visible APs, so it gets a higher default weight.
WEIGHT_CHANIM=2.0
WEIGHT_NEIGHBOR=1.0
WEIGHT_OBSS=0.3            # secondary tie-breaker inside the chanim penalty

log() {
    # Timestamp prefix uses /proc/uptime (seconds since boot) rather than
    # wall-clock time, specifically so it lines up directly with dmesg's
    # bracketed [seconds.microseconds] timestamps - after several rounds
    # of estimating gaps between our actions and dmesg lines by eye, exact
    # correlation is worth having built in rather than guessed at.
    _ts="$(awk '{print $1}' /proc/uptime 2>/dev/null)"
    logger -t "$LOGTAG" -- "$*"
    if [ -n "$_ts" ]; then
        echo "[${_ts}] $*" >&2
    else
        echo "$*" >&2
    fi
}

usage() {
    cat >&2 <<EOF
Usage: $0 [-i <ap_iface>] [-c <hostapd.conf>] [-s <scan_iface>] [-b 2.4|5|6] [options]

  -i, --ap-iface     Interface hostapd will bring up as AP (default: wlan1
                     if omitted)
  -s, --scan-iface   Interface to use for scanning (e.g. wlan0). Optional:
                     if omitted, a sibling interface on the same radio is
                     auto-detected; falls back to -i itself if none found.
  -c, --conf         hostapd config file to patch (default:
                     /etc/hostapd_<ap_iface>.conf if omitted)
  -b, --band         "2.4", "5" or "6" (default: 2.4)
      --no-dfs       Exclude DFS-only 5GHz channels from candidates (this
                     is now the DEFAULT - see ALLOW_DFS comments above)
      --allow-dfs    Allow DFS channels (only pass this once you've
                     confirmed DFS channels actually start hostapd on
                     your board - see ALLOW_DFS comments)
      --no-preflight Skip the radio-cleanup step entirely (advanced/testing)
      --no-restart   Don't restart hostapd/wpa_supplicant services this
                     script stopped
      --no-wpa-stop  Don't touch the global wpa_supplicant instance
      --settle-secs N  Override STEP_SETTLE_SECS (pause after each
                     preflight state change, default 2s)
      --final-settle-secs N  Override FINAL_SETTLE_SECS (pause after the
                     last preflight change before the first scan, default 5s)
      --systemctl-settle-secs N  Override SYSTEMCTL_SETTLE_SECS (pause
                     after EVERY systemctl stop/start in this script,
                     default 5s)
      --scan-attempts N  Override SCAN_MAX_ATTEMPTS (retry a failed scan
                     this many times before giving up, default 4)
      --scan-retry-secs N  Override SCAN_RETRY_BACKOFF_SECS (pause
                     between failed scan attempts, default 2s)
      --switch-margin N  Override HYSTERESIS_MARGIN_PCT (only switch away
                     from the current channel if the best candidate scores
                     at least N% better, default 20; 0 disables this)
      --restore-nm   Re-enable NetworkManager management of sibling
                     interfaces afterward (off by default, see comments)
  -h, --help         Show this help
EOF
    exit 1
}

# ----------------------------------------------------------------------
# Arg parsing
# ----------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        -i|--ap-iface)    AP_IFACE="$2"; AP_IFACE_EXPLICIT=1; shift 2 ;;
        -s|--scan-iface)  SCAN_IFACE="$2"; shift 2 ;;
        -c|--conf)        HOSTAPD_CONF="$2"; HOSTAPD_CONF_EXPLICIT=1; shift 2 ;;
        -b|--band)        BAND="$2"; BAND_EXPLICIT=1; shift 2 ;;
        --no-dfs)         ALLOW_DFS=0; shift ;;
        --allow-dfs)      ALLOW_DFS=1; shift ;;
        --no-preflight)   DO_PREFLIGHT=0; shift ;;
        --no-restart)     RESTART_HOSTAPD=0; shift ;;
        --no-wpa-stop)    STOP_WPA_SUPPLICANT=0; shift ;;
        --settle-secs)    STEP_SETTLE_SECS="$2"; shift 2 ;;
        --final-settle-secs) FINAL_SETTLE_SECS="$2"; shift 2 ;;
        --systemctl-settle-secs) SYSTEMCTL_SETTLE_SECS="$2"; shift 2 ;;
        --scan-attempts)  SCAN_MAX_ATTEMPTS="$2"; shift 2 ;;
        --scan-retry-secs) SCAN_RETRY_BACKOFF_SECS="$2"; shift 2 ;;
        --switch-margin)  HYSTERESIS_MARGIN_PCT="$2"; shift 2 ;;
        --restore-nm)     RESTORE_NM=1; shift ;;
        -h|--help)        usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

if [ "$AP_IFACE_EXPLICIT" -eq 0 ]; then
    log "no -i/--ap-iface given, defaulting to $AP_IFACE"
fi

if [ "$HOSTAPD_CONF_EXPLICIT" -eq 0 ]; then
    HOSTAPD_CONF="/etc/hostapd_${AP_IFACE}.conf"
    log "no -c/--conf given, defaulting to $HOSTAPD_CONF (derived from AP_IFACE=$AP_IFACE)"
fi

# ----------------------------------------------------------------------
# Auto-detect band from the target hostapd conf's hw_mode= if the caller
# didn't explicitly pass -b/--band. This matters for the templated
# systemd unit (wifi-select-channel@.service): the same unit file gets
# reused for every AP instance (hostapd@wlan0, hostapd@wlan1, ...), and
# those instances can run different bands (one 2.4GHz, one 5GHz) - a
# single hardcoded -b in the unit file would silently be wrong for
# whichever instance doesn't match it. Reading the conf's own hw_mode=
# instead means the same unit works correctly for any instance without
# per-instance editing.
#   hw_mode=a  -> 5GHz (this script doesn't currently distinguish 5 vs
#                 6GHz purely from hw_mode; pass -b 6 explicitly if you
#                 need the 6GHz candidate list instead)
#   hw_mode=b/g -> 2.4GHz
# Falls back to the BAND default (2.4) with a warning if hw_mode is
# missing, unrecognized, or the conf file doesn't exist yet.
# ----------------------------------------------------------------------
if [ "$BAND_EXPLICIT" -eq 0 ] && [ -f "$HOSTAPD_CONF" ]; then
    hw_mode="$(grep -m1 '^hw_mode=' "$HOSTAPD_CONF" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')"
    case "$hw_mode" in
        a)
            BAND="5"
            log "auto-detected band 5 from hw_mode=a in $HOSTAPD_CONF"
            ;;
        b|g)
            BAND="2.4"
            log "auto-detected band 2.4 from hw_mode=$hw_mode in $HOSTAPD_CONF"
            ;;
        "")
            log "no hw_mode= found in $HOSTAPD_CONF, using default band $BAND (pass -b explicitly to override)"
            ;;
        *)
            log "unrecognized hw_mode=$hw_mode in $HOSTAPD_CONF, using default band $BAND (pass -b explicitly to override)"
            ;;
    esac
fi

# Capture the CURRENTLY-configured channel before anything in this run
# touches the conf file, so score_channels' ranking can later be compared
# against it (see HYSTERESIS_MARGIN_PCT). Deliberately read this before
# preflight/scanning even begins, not right before writing, since nothing
# should have modified HOSTAPD_CONF by then anyway - this is just the
# clearest place to read "what was configured coming into this run".
CURRENT_CHANNEL="$(grep -m1 '^channel=' "$HOSTAPD_CONF" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')"

# ----------------------------------------------------------------------
# Legal channel tables (edit for your regulatory domain / hw_mode)
# ----------------------------------------------------------------------
CHANNELS_24="1 2 3 4 5 6 7 8 9 10 11 12 13"
CHANNELS_5_NONDFS="36 40 44 48 149 153 157 161 165"
CHANNELS_5_DFS="52 56 60 64 100 104 108 112 116 120 124 128 132 136 140 144"

case "$BAND" in
    2.4|5|6) ;;
    *) echo "Invalid band: $BAND (use 2.4, 5 or 6)" >&2; exit 1 ;;
esac

# Static fallback tables, only used if "wl channels" (queried live from the
# radio, see get_candidates_from_wl) is unavailable. Real hardware should
# always prefer the live list, since it automatically reflects the
# country/regulatory domain currently programmed into the firmware.
if [ "$BAND" = "2.4" ]; then
    CANDIDATES_FALLBACK="$CHANNELS_24"
elif [ "$BAND" = "5" ]; then
    if [ "$ALLOW_DFS" -eq 1 ]; then
        CANDIDATES_FALLBACK="$CHANNELS_5_NONDFS $CHANNELS_5_DFS"
    else
        CANDIDATES_FALLBACK="$CHANNELS_5_NONDFS"
    fi
else
    CANDIDATES_FALLBACK=""   # no static 6GHz table maintained; wl channels only
fi

# ----------------------------------------------------------------------
# Locking - avoid two instances racing on the same radio
# ----------------------------------------------------------------------
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    log "another instance is already running, exiting"
    exit 0
fi

# ----------------------------------------------------------------------
# Helper: is a given channel in the DFS set?
# ----------------------------------------------------------------------
is_dfs_channel() {
    _idc_target="$1"
    for _idc_c in $CHANNELS_5_DFS; do
        if [ "$_idc_c" = "$_idc_target" ]; then
            unset _idc_target _idc_c
            return 0
        fi
    done
    unset _idc_target _idc_c
    return 1
}

# ----------------------------------------------------------------------
# wl_probe - diagnostic helper, run this by hand once on real hardware to
# see the exact text your wl build/firmware produces, then adjust the
# parsing functions below if the layout differs.
# ----------------------------------------------------------------------
wl_probe() {
    echo "--- wl ver ---";            wl -i "$SCAN_IFACE" ver 2>&1
    echo "--- wl channels ---";       wl -i "$SCAN_IFACE" channels 2>&1
    echo "--- wl scan (trigger) ---"; wl -i "$SCAN_IFACE" scan 2>&1
    sleep "$SCAN_SETTLE_SECS"
    echo "--- wl scanresults ---";    wl -i "$SCAN_IFACE" scanresults 2>&1
    echo "--- wl chanim_stats ---";   wl -i "$SCAN_IFACE" chanim_stats 2>&1
}

# ----------------------------------------------------------------------
# get_scan_wl - populate /tmp/.acs_channel_counts with "channel rssi"
# lines by parsing "wl scanresults". Returns 0 if at least one usable
# record was parsed, 1 otherwise (caller should then fall back to iw).
#
# Validated against real "wl scanresults" output captured on ccmp25-dvk
# (see samples/scanresults.txt). Real-world quirk confirmed on hardware:
# the kernel occasionally interleaves a console message into the middle
# of a physical line (observed: an "oversize return buffer" brcmfmac
# warning printed mid-line, splitting "Flags: RSSI on-channel Channel:
# 40u" across two physical lines). The parser below is robust to this
# because it groups all physical lines between two "SSID:" markers into
# one record and scans every line in that record independently for a
# "Channel:" / "RSSI:" match, rather than assuming a fixed line layout.
# We prefer the unambiguous "Primary channel:" field when present (it is
# the actual control channel, distinct from the VHT/HE "Chanspec:" center
# channel) and fall back to "Channel:" (stripping the trailing u/l
# HT40-sideband suffix, e.g. "40u" -> "40") when it is not.
# ----------------------------------------------------------------------
get_scan_wl_once() {
    out="/tmp/.acs_wl_scanresults.$$"
    rm -f "$out"

    if ! command -v wl >/dev/null 2>&1; then
        log "wl tool not found, skipping wl scan path"
        return 1
    fi

    if ! wl -i "$SCAN_IFACE" scan >/dev/null 2>&1; then
        log "wl scan failed to start on $SCAN_IFACE"
        return 1
    fi
    sleep "$SCAN_SETTLE_SECS"

    if ! wl -i "$SCAN_IFACE" scanresults >"$out" 2>/dev/null; then
        log "wl scanresults returned an error"
        rm -f "$out"
        return 1
    fi

    if [ ! -s "$out" ]; then
        log "wl scanresults returned empty output"
        rm -f "$out"
        return 1
    fi

    # Split into per-BSS records at each "SSID:" line, then pull the
    # Primary channel: / Channel: and RSSI: fields out of each record.
    awk '
        BEGIN { rec = "" }
        /SSID:/ {
            if (rec != "") print rec
            rec = $0
            next
        }
        { rec = rec "\n" $0 }
        END { if (rec != "") print rec }
    ' "$out" \
    | awk -v RS='' '
        {
            ch = ""; ch_fallback = ""; rssi = "";
            n = split($0, lines, "\n");
            for (i = 1; i <= n; i++) {
                line = lines[i];
                # Authoritative: "Primary channel: <n>" (control channel)
                if (match(line, /[Pp]rimary channel:[ \t]*[0-9]+/)) {
                    m = substr(line, RSTART, RLENGTH);
                    sub(/[Pp]rimary channel:[ \t]*/, "", m);
                    ch = m;
                }
                # Fallback: "Channel: <n>[u|l]" - digits only, u/l suffix
                # is naturally excluded since [0-9]+ stops at the letter.
                if (match(line, /Channel:[ \t]*[0-9]+/)) {
                    m = substr(line, RSTART, RLENGTH);
                    sub(/Channel:[ \t]*/, "", m);
                    ch_fallback = m;
                }
                if (match(line, /RSSI:[ \t]*-?[0-9]+/)) {
                    m = substr(line, RSTART, RLENGTH);
                    sub(/RSSI:[ \t]*/, "", m);
                    rssi = m;
                }
            }
            if (ch == "") ch = ch_fallback;
            if (ch != "" && rssi != "") print ch, rssi
        }
    ' > /tmp/.acs_channel_counts

    rm -f "$out"

    if [ -s /tmp/.acs_channel_counts ]; then
        log "wl scan path produced $(wc -l < /tmp/.acs_channel_counts) BSS records"
        return 0
    fi

    log "wl scan path parsed 0 usable records (format mismatch? see wl_probe)"
    return 1
}

# ----------------------------------------------------------------------
# get_scan_wl - retry wrapper around get_scan_wl_once().
#
# Root cause found via dmesg timestamp correlation on real hardware: a
# "brcmf_generic_offload_config: successfully set ..." message appeared
# only ~3ms before an escan failure (-52), and similar offload_config
# messages recurred roughly every ~5 seconds throughout an otherwise idle
# period (measured gaps: ~5.18s, ~4.85s, ~5.44s) - independent of anything
# this script was doing. That points to brcmfmac running its own internal
# periodic housekeeping/reconfig cycle (roughly every ~5s), and a scan
# request that happens to land inside that window gets rejected. Fixed,
# 5-second-ish settle delays can't reliably dodge this, since we have no
# way to know the driver's internal timer phase from userspace - and a
# delay that happens to be a near-multiple of the driver's own period can
# actually make collisions MORE likely, not less.
#
# So instead of chasing the exact delay needed, retry a failed scan a
# few times with a short gap - much more likely to land in a quiet window
# eventually than any single fixed wait, regardless of the driver's
# internal timing. (SCAN_MAX_ATTEMPTS / SCAN_RETRY_BACKOFF_SECS are
# declared with the other defaults near the top of this file, not here,
# so that --scan-attempts/--scan-retry-secs parsed near the top of the
# script aren't clobbered by a later plain assignment overwriting them
# during normal top-to-bottom execution - this is the same class of bug
# as the is_dfs_channel variable-scope issue from earlier testing.)
# ----------------------------------------------------------------------
get_scan_wl() {
    attempt=1
    while [ "$attempt" -le "$SCAN_MAX_ATTEMPTS" ]; do
        if [ "$attempt" -gt 1 ]; then
            log "wl scan attempt $attempt/$SCAN_MAX_ATTEMPTS"
        fi
        if get_scan_wl_once; then
            return 0
        fi
        if [ "$attempt" -lt "$SCAN_MAX_ATTEMPTS" ]; then
            # Confirmed on real hardware (see comments above get_scan_wl_once
            # / SCAN_MAX_ATTEMPTS): a constant retry gap is the wrong fix -
            # real testing showed 4 straight wl attempts, evenly spaced
            # ~6s apart, ALL failing, while a differently-timed "iw" retry
            # shortly after succeeded. That points to retries landing on
            # the same phase of whatever brief recurring condition this is
            # every time, not "not waiting long enough" - so the backoff
            # is deliberately varied (increasing) between attempts here,
            # rather than constant, to avoid repeatedly probing the same
            # phase.
            backoff=$((SCAN_RETRY_BACKOFF_SECS + attempt - 1))
            log "wl scan attempt $attempt/$SCAN_MAX_ATTEMPTS failed, retrying after ${backoff}s (varied on purpose - see get_scan_wl comments: real testing showed a CONSTANT retry gap kept landing on the same phase of a brief recurring driver condition every time)"
            sleep "$backoff"
        fi
        attempt=$((attempt + 1))
    done
    log "wl scan path exhausted $SCAN_MAX_ATTEMPTS attempts"
    return 1
}

# ----------------------------------------------------------------------
# get_scan_iw - fallback using plain nl80211 "iw scan". Frequency -> channel
# conversion covers 2.4GHz and 5GHz.
# ----------------------------------------------------------------------
freq_to_channel() {
    # Confirmed on real hardware: this system's "iw scan" prints freq: as
    # e.g. "2412.0" (with a trailing ".0"), not a bare integer - POSIX
    # shell's [ -ge/-le ] and $(( )) both require an integer, so strip any
    # decimal part before comparing/computing (bash/dash integer ops don't
    # understand "2412.0" and error out with "integer expression expected").
    freq="${1%%.*}"
    if [ -z "$freq" ]; then
        echo ""
        return
    fi
    if [ "$freq" -ge 2412 ] && [ "$freq" -le 2484 ]; then
        if [ "$freq" -eq 2484 ]; then
            echo 14
        else
            echo $(( (freq - 2412) / 5 + 1 ))
        fi
    elif [ "$freq" -ge 5000 ] && [ "$freq" -le 5895 ]; then
        echo $(( (freq - 5000) / 5 ))
    else
        echo ""
    fi
}

get_scan_iw_once() {
    if ! command -v iw >/dev/null 2>&1; then
        log "iw tool not found, cannot fall back"
        return 1
    fi

    ip link set "$SCAN_IFACE" up 2>/dev/null

    scan_out="$(iw dev "$SCAN_IFACE" scan 2>/dev/null)"
    if [ -z "$scan_out" ]; then
        log "iw scan on $SCAN_IFACE returned nothing"
        return 1
    fi

    : > /tmp/.acs_channel_counts
    echo "$scan_out" | awk '
        /^BSS /                { sig="" ; freq="" }
        /freq:/                { freq = $2 }
        /signal:/               { sig = $2 }
        /^BSS / && prevfreq != "" { }
        {
            if (freq != "" && sig != "") {
                print freq, sig
                freq=""; sig=""
            }
        }
    ' >> /tmp/.acs_freqs

    # Convert frequency to channel
    while read -r freq sig; do
        ch="$(freq_to_channel "$freq")"
        [ -n "$ch" ] && echo "$ch $sig" >> /tmp/.acs_channel_counts
    done < /tmp/.acs_freqs
    rm -f /tmp/.acs_freqs

    if [ -s /tmp/.acs_channel_counts ]; then
        log "iw scan fallback produced $(wc -l < /tmp/.acs_channel_counts) BSS records"
        return 0
    fi
    return 1
}

# Retry wrapper - same rationale as get_scan_wl()'s wrapper above (racing
# against the driver's own internal ~5s periodic reconfig cycle).
get_scan_iw() {
    attempt=1
    while [ "$attempt" -le "$SCAN_MAX_ATTEMPTS" ]; do
        if [ "$attempt" -gt 1 ]; then
            log "iw scan attempt $attempt/$SCAN_MAX_ATTEMPTS"
        fi
        if get_scan_iw_once; then
            return 0
        fi
        if [ "$attempt" -lt "$SCAN_MAX_ATTEMPTS" ]; then
            backoff=$((SCAN_RETRY_BACKOFF_SECS + attempt - 1))
            log "iw scan attempt $attempt/$SCAN_MAX_ATTEMPTS failed, retrying after ${backoff}s (varied on purpose, same rationale as get_scan_wl)"
            sleep "$backoff"
        fi
        attempt=$((attempt + 1))
    done
    log "iw scan fallback exhausted $SCAN_MAX_ATTEMPTS attempts"
    return 1
}

# ----------------------------------------------------------------------
# get_chanim_wl - "wl chanim_stats" exposes the firmware's own channel
# interference monitor (real measured airtime occupancy), which is a much
# better congestion signal than just counting neighboring BSSes.
#
# Validated on real hardware (see samples/chanim_stats.txt). Output is a
# repeated "header line, data line" pair per chanspec:
#
#   chanspec tx inbss obss nocat nopkt doze txop goodtx badtx myrx \
#            glitch badplcp knoise idle timestamp
#   0x1001   2  6     10   1     6     0    75   0      0     0    \
#            560    0       -91    90   134576347
#
# "chanspec" is a 16-bit field, confirmed by decoding against the live
# "wl channels" list on ccmp25-dvk:
#   band    = chanspec & 0xC000  (0x0000=2.4GHz, 0xC000=5GHz, 0x8000=6GHz)
#   channel = chanspec & 0x00FF  (literal channel number for every band)
#
# We use "idle" (percent of time the channel was idle - higher is better)
# as the primary congestion signal, with "obss" (percent busy specifically
# due to other Wi-Fi BSSes) as a smaller tie-breaking weight.
# ----------------------------------------------------------------------
get_chanim_wl() {
    [ "$ENABLE_CHANIM" -eq 1 ] || return 1
    command -v wl >/dev/null 2>&1 || return 1

    raw="$(wl -i "$SCAN_IFACE" chanim_stats 2>/dev/null)"
    [ -n "$raw" ] || return 1

    target_band_val=""
    case "$BAND" in
        2.4) target_band_val=0 ;;
        5)   target_band_val=49152 ;;   # 0xC000
        6)   target_band_val=32768 ;;   # 0x8000
    esac

    : > /tmp/.acs_chanim_stats
    echo "$raw" | while read -r cs tx inbss obss nocat nopkt doze txop \
                            goodtx badtx myrx glitch badplcp knoise idle ts; do
        case "$cs" in
            0x*[0-9a-fA-F]) ;;
            *) continue ;;   # skips the repeated header lines / junk
        esac
        band=$(( cs & 0xC000 ))
        ch=$(( cs & 0x00FF ))
        [ "$band" = "$target_band_val" ] || continue
        echo "$ch $idle $obss $glitch" >> /tmp/.acs_chanim_stats
    done

    if [ -s /tmp/.acs_chanim_stats ]; then
        log "chanim data: $(wc -l < /tmp/.acs_chanim_stats) channels in band $BAND"
        return 0
    fi
    log "chanim_stats produced no entries for band $BAND"
    return 1
}

# ----------------------------------------------------------------------
# get_candidates_from_chanim - derive the 6GHz candidate list from "wl
# chanim_stats" chanspec decode, instead of "wl channels".
#
# Why this exists: "wl channels" returns bare channel numbers with no
# band tag, and 6GHz channel numbers (1,5,9,13...233) numerically overlap
# with both 2.4GHz (1-14) and 5GHz (36-165) channel numbers - there is no
# way to confirm a number from that list is really a 6GHz channel (this
# is exactly what caused a real bug: an earlier, over-permissive band=6
# filter in get_candidates_from_wl() silently accepted the entire
# 2.4+5GHz list as "6GHz candidates"). "wl chanim_stats", by contrast,
# reports a chanspec (not a bare number) per entry, and chanspec's band
# bits ARE unambiguous - band = chanspec & 0xC000, with 0x8000 = 6GHz,
# confirmed against real chanim_stats output (see samples/ and
# get_chanim_wl comments). get_chanim_wl() already does this decode and
# already filters to entries matching $BAND - so for BAND=6, just call
# it early (before scanning) and read the distinct channel numbers back
# out of the file it produces, instead of touching "wl channels" at all.
# ----------------------------------------------------------------------
get_candidates_from_chanim() {
    [ "$BAND" = "6" ] || return 1

    get_chanim_wl || return 1
    [ -s /tmp/.acs_chanim_stats ] || return 1

    result="$(awk '{print $1}' /tmp/.acs_chanim_stats | sort -un | xargs)"
    [ -n "$result" ] || return 1
    CANDIDATES="$result"
    return 0
}

# ----------------------------------------------------------------------
# get_candidates_from_wl - query the radio's own live legal-channel list
# via "wl channels" instead of relying on the static regulatory tables.
# This automatically follows whatever country/regulatory domain is
# currently programmed into the firmware (validated: on ccmp25-dvk, "wl
# channels" for the 5GHz-configured wlan1 interface returned exactly
# "36 40 44 48 52 56 60 64 100 104 108 112 116 120 124 128 132 136 140
# 144 149 153 157 161 165", matching the DFS/non-DFS split we assumed in
# the static table). Falls back to CANDIDATES_FALLBACK if unavailable.
# ----------------------------------------------------------------------
get_candidates_from_wl() {
    # band=6 is deliberately never derived from "wl channels" here - see
    # the detailed comment further down (past the loop) for exactly why:
    # short version is that bare channel numbers from this command can't
    # be reliably distinguished as 6GHz vs 2.4/5GHz, and guessing wrong
    # here previously caused a real, silent failure on real hardware.
    if [ "$BAND" = "6" ]; then
        return 1
    fi

    command -v wl >/dev/null 2>&1 || return 1
    chans="$(wl -i "$SCAN_IFACE" channels 2>/dev/null)"
    [ -n "$chans" ] || return 1

    result=""
    for c in $chans; do
        case "$c" in
            ''|*[!0-9]*) continue ;;   # ignore any non-numeric token
        esac
        case "$BAND" in
            2.4) [ "$c" -ge 1 ] && [ "$c" -le 14 ]  && result="$result $c" ;;
            5)   [ "$c" -ge 36 ] && [ "$c" -le 177 ] && {
                     if [ "$ALLOW_DFS" -eq 0 ] && is_dfs_channel "$c"; then
                         :   # excluded by policy
                     else
                         result="$result $c"
                     fi
                 } ;;
        esac
    done

    # NOTE on why band=6 is excluded above (not just left as a case
    # branch that happens to match nothing): "wl channels" returns a flat
    # list of bare channel numbers with NO band tag, and 6GHz channel
    # numbers (1,5,9,13...233) numerically OVERLAP with both 2.4GHz
    # (1-14) and 5GHz (36-165) channel numbers. A permissive
    # "1 <= c <= 233" range check (an earlier version of this function
    # had exactly that) can't actually distinguish a real 6GHz channel
    # from a 2.4GHz/5GHz one at all - confirmed on real hardware: with
    # -b 6 requested, that bug caused the *entire* combined 2.4+5GHz list
    # to be silently accepted as "6GHz candidates" (every number in it
    # also happens to fall in 1-233), the scorer picked channel 2 (a
    # 2.4GHz channel), and that got written into a hw_mode=a config,
    # which hostapd then rejected - the AP silently failed to start.
    # Falling through to the (currently absent) static 6GHz fallback
    # table and aborting cleanly is safer than silently writing a
    # wrong/invalid channel. If you need working 6GHz candidate
    # derivation, prefer building the list from get_chanim_wl()'s
    # chanspec decode instead (chanspec DOES carry an unambiguous band
    # bit, unlike the bare "wl channels" list) - this hasn't been
    # implemented yet, flagged as unvalidated in the README.

    result="$(echo "$result" | xargs)"   # trim whitespace
    [ -n "$result" ] || return 1
    CANDIDATES="$result"
    return 0
}

# ----------------------------------------------------------------------
# score_channels - combine neighbor-BSS data (+ chanim data if present)
# into a single score per candidate channel, lower score = better.
# ----------------------------------------------------------------------
score_channels() {
    : > /tmp/.acs_scores

    for ch in $CANDIDATES; do
        # Count neighboring BSSes reported on/adjacent to this channel and
        # sum their (positive-shifted) RSSI as an interference penalty.
        # Only applies bleed-over distance weighting on 2.4GHz, where
        # adjacent channels physically overlap; on 5/6GHz channels are
        # non-overlapping so only an exact match counts.
        neighbor_penalty=$(awk -v target="$ch" -v band="$BAND" '
            {
                ch=$1; rssi=$2;
                d = (ch > target) ? ch - target : target - ch;
                if (d == 0)                         w = 1.0;
                else if (band == "2.4" && d <= 4)    w = 0.5;
                else                                 next;
                contrib = (rssi + 100) * w;
                if (contrib < 0) contrib = 0;
                sum += contrib;
            }
            END { printf "%.2f", sum+0 }
        ' /tmp/.acs_channel_counts)

        # Firmware-measured airtime occupancy (100-idle) plus a smaller
        # weight on obss (specifically-other-BSS busy time) as tie-breaker.
        # If this exact channel has no chanim sample (e.g. the firmware
        # hasn't scanned it yet), fall back to the *band average* penalty
        # rather than 0 - an unmeasured channel should be treated as
        # "unknown/average", not silently assumed to be the cleanest
        # option just because we have no data for it.
        chanim_penalty=0
        if [ -f /tmp/.acs_chanim_stats ] && [ -s /tmp/.acs_chanim_stats ]; then
            chanim_penalty=$(awk -v target="$ch" -v wobss="$WEIGHT_OBSS" '
                $1 == target { idle=$2; obss=$3; found=1 }
                { sum_idle += $2; sum_obss += $3; n++ }
                END {
                    if (found) {
                        printf "%.2f", (100 - idle) + wobss * obss
                    } else if (n > 0) {
                        avg_idle = sum_idle / n; avg_obss = sum_obss / n;
                        printf "%.2f", (100 - avg_idle) + wobss * avg_obss
                    } else {
                        print 0
                    }
                }
            ' /tmp/.acs_chanim_stats)
        fi

        # Non-overlap bonus for the classic 2.4GHz 1/6/11 set
        bonus=0
        if [ "$BAND" = "2.4" ]; then
            case "$ch" in
                1|6|11) bonus=-5 ;;
            esac
        fi

        # DFS penalty (CAC delay cost) even when DFS channels are allowed
        dfs_penalty=0
        if [ "$BAND" = "5" ] && is_dfs_channel "$ch"; then
            dfs_penalty=8
        fi

        total=$(awk -v np="$neighbor_penalty" -v cp="$chanim_penalty" \
                   -v wn="$WEIGHT_NEIGHBOR" -v wc="$WEIGHT_CHANIM" \
                   -v b="$bonus" -v d="$dfs_penalty" \
                   'BEGIN{printf "%.2f", wn*np + wc*cp + b + d}')
        echo "$ch $total" >> /tmp/.acs_scores
    done

    # Secondary numeric sort key (channel number) makes tie-breaking
    # deterministic - prefer the lower channel number among equal scores.
    sort -k2,2n -k1,1n /tmp/.acs_scores
}

# ----------------------------------------------------------------------
# update_hostapd_channel - patch the "channel=" line in the target conf.
# ----------------------------------------------------------------------
update_hostapd_channel() {
    ch="$1"
    conf="$2"

    if [ ! -f "$conf" ]; then
        log "hostapd conf $conf does not exist"
        return 1
    fi

    if grep -q '^channel=' "$conf"; then
        sed -i "s/^channel=.*/channel=$ch/" "$conf"
    else
        echo "channel=$ch" >> "$conf"
    fi
    log "wrote channel=$ch to $conf"

    # Keep VHT/HE center-frequency-segment-0 index in sync with the new
    # channel, IF the conf already has these lines (never add them if
    # they're not already there - only sync what the operator explicitly
    # configured). This chip is 20MHz-only (1x1 SISO, per the Type 2FY
    # datasheet), and in pure 20MHz operation the VHT/HE center-frequency
    # index always equals the primary channel number itself, for any
    # band - so no separate per-channel lookup table is needed, just
    # mirror whatever we wrote to channel=. Added specifically because a
    # Wi-Fi 6 tuned config template (see hostapd_wlan1_wifi6_ch165.conf)
    # sets vht_oper_centr_freq_seg0_idx=/he_oper_centr_freq_seg0_idx=
    # explicitly - leaving those stale after changing channel= would
    # mismatch the actual channel and could make hostapd refuse to start.
    for key in vht_oper_centr_freq_seg0_idx he_oper_centr_freq_seg0_idx; do
        if grep -q "^${key}=" "$conf"; then
            sed -i "s/^${key}=.*/${key}=$ch/" "$conf"
            log "kept ${key}=$ch in sync with the new channel in $conf"
        fi
    done
}

# ----------------------------------------------------------------------
# get_phy_for_iface / list_sibling_ifaces - parse `iw dev` to discover
# radio topology. Validated against real ccmp25-dvk output where wlan0
# (managed) and wlan1 (AP) both showed up under the same "phy#0" block -
# i.e. one physical radio exposing two virtual interfaces, NOT two
# independent radios. "Unnamed/non-netdev interface" blocks (P2P-device)
# have no "Interface <name>" line and are correctly skipped.
# ----------------------------------------------------------------------
get_phy_for_iface() {
    _target="$1"
    command -v iw >/dev/null 2>&1 || return 1
    iw dev 2>/dev/null | awk -v target="$_target" '
        /^phy#/ { phy=$0 }
        /^[ \t]*Interface / { if ($2==target) { print phy; found=1; exit } }
        END { exit(found?0:1) }
    '
}

list_sibling_ifaces() {
    _phy="$1"
    _self="$2"
    command -v iw >/dev/null 2>&1 || return 1
    iw dev 2>/dev/null | awk -v phy="$_phy" -v self="$_self" '
        /^phy#/ { curphy=$0 }
        /^[ \t]*Interface / { if (curphy==phy && $2!=self) print $2 }
    '
}

# ----------------------------------------------------------------------
# preflight - stop anything that could be fighting the AP interface's
# radio for control before we try to scan. On single-PHY MCC hardware
# (confirmed on ccmp25-dvk: wlan0 + wlan1 both under phy#0) this matters
# even when scanning from a *different* virtual interface than the AP -
# real testing showed a scan from wlan0 while hostapd was up on wlan1
# left the radio in a state where the next `systemctl restart
# hostapd@wlan1` failed with "brcmf_cfg80211_start_ap: SET SSID error
# (-52)". So: stop hostapd on the AP interface (and any sibling running
# its own hostapd), and tell NetworkManager to stop managing every
# sibling interface on the same phy, before touching the radio.
# ----------------------------------------------------------------------
preflight() {
    [ "$DO_PREFLIGHT" -eq 1 ] || { log "preflight: skipped (--no-preflight)"; return 0; }

    log "preflight: checking radio topology for $AP_IFACE"
    ap_phy="$(get_phy_for_iface "$AP_IFACE")"
    if [ -z "$ap_phy" ]; then
        log "preflight: could not resolve phy for $AP_IFACE via 'iw dev' (interface missing, or iw not available) - continuing without preflight cleanup"
        return 0
    fi
    log "preflight: $AP_IFACE is on $ap_phy"

    # Global wpa_supplicant instance (started with -u for D-Bus/global
    # control, no static -i interface) can still be bound to a wifi
    # interface behind the scenes even when `nmcli` reports that interface
    # as "unmanaged" - confirmed on real hardware: `nmcli device status`
    # showed wlan0 unmanaged, yet a "p2p-dev-wlan0" virtual device existed
    # (which wpa_supplicant creates when it drives an interface with P2P
    # support), and stopping wpa_supplicant was what finally let scanning
    # on wlan0 succeed - not any of the AP-interface-side changes above.
    #
    # Don't gate this on `systemctl is-active` either: confirmed on real
    # hardware that it reported wpa_supplicant.service as NOT active in
    # one test run while `ps aux` clearly showed the process running.
    # (Note: it IS a normal, properly-registered Type=dbus systemd unit -
    # `systemctl status` / `busctl status fi.w1.wpa_supplicant1` both
    # confirm that when checked directly, so don't assume it's started
    # outside systemd. Why that one is-active check disagreed isn't
    # pinned down, and it doesn't matter: just don't depend on it.) So:
    # always try `systemctl stop`, AND separately check for the actual
    # process by name and kill it directly if still present - belt and
    # suspenders, matching the two-step recipe that worked when tested by
    # hand (`systemctl stop wpa_supplicant || killall wpa_supplicant`).
    if [ "$STOP_WPA_SUPPLICANT" -eq 1 ]; then
        wpa_touched=0
        if command -v systemctl >/dev/null 2>&1; then
            log "preflight: stopping wpa_supplicant.service (harmless if it doesn't exist or is already stopped)"
            systemctl stop wpa_supplicant.service 2>/dev/null
            wpa_touched=1
        fi
        if command -v pgrep >/dev/null 2>&1; then
            if pgrep -x wpa_supplicant >/dev/null 2>&1; then
                log "preflight: wpa_supplicant process still present after systemctl stop, killing it directly"
                killall wpa_supplicant 2>/dev/null
                wpa_touched=1
            fi
        elif pidof wpa_supplicant >/dev/null 2>&1; then
            log "preflight: wpa_supplicant process still present after systemctl stop, killing it directly"
            killall wpa_supplicant 2>/dev/null
            wpa_touched=1
        fi
        [ "$wpa_touched" -eq 1 ] && HOSTAPD_STOPPED="$HOSTAPD_STOPPED wpa_supplicant.service"
        if [ "$wpa_touched" -eq 1 ]; then
            log "preflight: pausing ${SYSTEMCTL_SETTLE_SECS}s after touching wpa_supplicant"
            sleep "$SYSTEMCTL_SETTLE_SECS"
        fi
    fi

    # Stop hostapd for the AP interface itself. Always attempt this (not
    # gated on is-active): real-world testing showed hostapd@wlan1.service
    # reporting "inactive (dead) since 25min ago" in systemd while the
    # underlying vif was still stuck in AP mode - so systemd's notion of
    # "active" isn't a reliable signal here either way. `systemctl stop` on
    # an already-inactive unit is a harmless no-op.
    if command -v systemctl >/dev/null 2>&1; then
        AP_HOSTAPD_SVC="hostapd@${AP_IFACE}.service"
        # Don't gate this on a pre-check: `systemctl list-unit-files` only
        # lists the *template* (hostapd@.service), not instantiated names
        # like "hostapd@wlan1.service", so a pre-check for the instantiated
        # name incorrectly reports "not found" even when the unit is very
        # much real (confirmed on real hardware: `systemctl status
        # hostapd@wlan1` showed it Loaded, just our existence check was
        # asking the wrong question). Just stop it unconditionally -
        # harmless no-op on a system where it doesn't exist.
        log "preflight: stopping $AP_HOSTAPD_SVC (harmless if it doesn't exist or is already stopped)"
        systemctl stop "$AP_HOSTAPD_SVC" 2>/dev/null
        HOSTAPD_STOPPED="$HOSTAPD_STOPPED $AP_HOSTAPD_SVC"
        log "preflight: pausing ${SYSTEMCTL_SETTLE_SECS}s after stopping $AP_HOSTAPD_SVC (hostapd needs longer to settle than a plain process kill - confirmed on real hardware)"
        sleep "$SYSTEMCTL_SETTLE_SECS"

        if systemctl is-active --quiet hostapd.service 2>/dev/null; then
            log "preflight: stopping hostapd.service"
            systemctl stop hostapd.service 2>/dev/null
            HOSTAPD_STOPPED="$HOSTAPD_STOPPED hostapd.service"
            sleep "$SYSTEMCTL_SETTLE_SECS"
        fi
    else
        log "preflight: systemctl not found, skipping hostapd stop (make sure nothing is driving $AP_IFACE before running this script)"
    fi

    # IMPORTANT (confirmed on real hardware): stopping the hostapd *process*
    # is not enough. brcmfmac can leave the AP interface's cfg80211 vif
    # sitting in "type AP" on its last-used channel even after hostapd has
    # exited (systemd showing hostapd@wlan1.service as long since inactive,
    # while `iw dev` still shows wlan1 as "type AP, channel 132") - and that
    # alone is enough to make the shared radio reject a scan from a sibling
    # interface (brcmf_cfg80211_scan: scan error (-52)), same failure as
    # when hostapd was actively running. So unconditionally bring the AP
    # interface down here, regardless of what systemd thinks its state is.
    ap_flags="$(ip link show "$AP_IFACE" 2>/dev/null | sed -n '1s/.*<\(.*\)>.*/\1/p')"
    case ",${ap_flags}," in
        *,UP,*) AP_IFACE_WAS_UP=1 ;;
    esac
    log "preflight: bringing $AP_IFACE down to release the radio (was up: ${AP_IFACE_WAS_UP:-0})"
    ip link set "$AP_IFACE" down 2>/dev/null
    sleep "$STEP_SETTLE_SECS"

    # Confirmed on real hardware: bringing the interface administratively
    # down is NOT sufficient by itself - a scan from the sibling vif still
    # failed with the same "brcmf_cfg80211_scan: scan error (-52)"
    # afterward. The vif's *type* (AP) and its channel context are
    # apparently retained by brcmfmac independent of the interface's
    # up/down state, and that's what blocks the shared radio from
    # channel-hopping to scan. Switching the vif's type away from AP
    # while it's down releases that channel context. hostapd doesn't need
    # us to switch it back afterward - its own nl80211 driver backend sets
    # the interface to AP type itself as a normal part of starting up.
    if command -v iw >/dev/null 2>&1; then
        log "preflight: switching $AP_IFACE off AP type to fully release the channel context"
        iw dev "$AP_IFACE" set type managed 2>/dev/null
    fi

    # Every other interface sharing the same phy is a potential source of
    # contention (NetworkManager periodic scans, another hostapd, etc.)
    siblings="$(list_sibling_ifaces "$ap_phy" "$AP_IFACE")"
    for sib in $siblings; do
        log "preflight: found sibling interface $sib on the same radio ($ap_phy)"

        if command -v systemctl >/dev/null 2>&1; then
            svc="hostapd@${sib}.service"
            if systemctl is-active --quiet "$svc" 2>/dev/null; then
                log "preflight: stopping $svc (hostapd running on sibling interface)"
                systemctl stop "$svc" 2>/dev/null
                HOSTAPD_STOPPED="$HOSTAPD_STOPPED $svc"
                sleep "$SYSTEMCTL_SETTLE_SECS"
            fi
        fi

        if command -v nmcli >/dev/null 2>&1; then
            nm_state="$(nmcli -t -f DEVICE,STATE device status 2>/dev/null | awk -F: -v d="$sib" '$1==d{print $2}')"
            if [ -n "$nm_state" ] && [ "$nm_state" != "unmanaged" ]; then
                log "preflight: $sib is NetworkManager-managed (state: $nm_state) - disconnecting and un-managing it"
                nmcli device disconnect "$sib" >/dev/null 2>&1
                nmcli device set "$sib" managed no >/dev/null 2>&1
                NM_UNMANAGED="$NM_UNMANAGED $sib"
            fi
        fi

        ip link set "$sib" up 2>/dev/null
    done

    # Auto-pick a scan interface if the caller didn't specify one.
    if [ -z "$SCAN_IFACE" ]; then
        auto="$(echo "$siblings" | awk 'NF{print; exit}')"
        if [ -n "$auto" ]; then
            SCAN_IFACE="$auto"
            log "preflight: auto-selected scan interface: $SCAN_IFACE"
        else
            SCAN_IFACE="$AP_IFACE"
            log "preflight: no sibling interface found on $ap_phy, falling back to scanning on $AP_IFACE itself"
        fi
    fi

    # IMPORTANT (this was the actual bug in the previous version): the
    # final settle pause needs to happen AFTER $SCAN_IFACE is brought up,
    # not before. On real hardware, bringing $SCAN_IFACE up right before
    # scanning with zero pause still reproduced the same
    # "brcmf_cfg80211_scan: scan error (-52)" - the previous version of
    # this script slept BEFORE the sibling-interface loop above (i.e.
    # before wlan0 was brought up), which meant wlan0 itself got no
    # settle time at all despite the log message claiming it did. The
    # hand-tested working sequence was specifically: ...set type managed
    # -> ip link set wlan0 up -> sleep 10 -> wl scan. Match that order
    # here: bring the scan interface up FIRST, then pause, then return to
    # the caller's scan attempt.
    ip link set "$SCAN_IFACE" up 2>/dev/null
    log "preflight: final settle pause (${FINAL_SETTLE_SECS}s) after bringing $SCAN_IFACE up, before scanning - confirmed necessary on real hardware (the working hand-tested sequence had this pause AFTER 'ip link set wlan0 up', not before)"
    sleep "$FINAL_SETTLE_SECS"
    return 0
}

# ----------------------------------------------------------------------
# postflight - undo what preflight() changed, once we're done with the
# radio: restart any hostapd instances we stopped (so the AP comes back
# up, now with the freshly-selected channel already written to its
# config), and optionally hand sibling interfaces back to NetworkManager.
# ----------------------------------------------------------------------
postflight() {
    if [ "$RESTART_HOSTAPD" -eq 1 ] && [ -n "$HOSTAPD_STOPPED" ]; then
        for svc in $HOSTAPD_STOPPED; do
            log "postflight: starting $svc"
            systemctl start "$svc" 2>/dev/null
            log "postflight: pausing ${SYSTEMCTL_SETTLE_SECS}s after starting $svc"
            sleep "$SYSTEMCTL_SETTLE_SECS"
        done
    elif [ -n "$HOSTAPD_STOPPED" ]; then
        log "postflight: left stopped (--no-restart): $HOSTAPD_STOPPED"
        # We're not starting hostapd (which would normally bring the
        # interface back up itself), so at least restore the interface's
        # own up/down state to what we found it in.
        if [ "$AP_IFACE_WAS_UP" = "1" ]; then
            log "postflight: bringing $AP_IFACE back up (was up before preflight)"
            ip link set "$AP_IFACE" up 2>/dev/null
        fi
    fi

    if [ "$RESTORE_NM" -eq 1 ] && [ -n "$NM_UNMANAGED" ]; then
        for sib in $NM_UNMANAGED; do
            log "postflight: restoring NetworkManager management of $sib"
            nmcli device set "$sib" managed yes >/dev/null 2>&1
        done
    elif [ -n "$NM_UNMANAGED" ]; then
        log "postflight: left un-managed by NetworkManager (pass --restore-nm to undo): $NM_UNMANAGED"
    fi
}

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
rm -f /tmp/.acs_channel_counts /tmp/.acs_chanim_stats

preflight

[ -n "$SCAN_IFACE" ] || { log "no scan interface available (AP interface missing and no sibling found), aborting"; exit 2; }

if [ "$BAND" = "6" ] && get_candidates_from_chanim; then
    log "candidate channels from live 'wl chanim_stats' chanspec decode: $CANDIDATES"
elif get_candidates_from_wl; then
    log "candidate channels from live 'wl channels': $CANDIDATES"
else
    CANDIDATES="$CANDIDATES_FALLBACK"
    if [ -z "$CANDIDATES" ]; then
        log "no live channel list and no static fallback table for band $BAND, aborting"
        postflight
        exit 2
    fi
    log "using static fallback candidate channels: $CANDIDATES"
fi

if get_scan_wl; then
    SOURCE="wl"
elif get_scan_iw; then
    SOURCE="iw"
else
    log "no scan data available from wl or iw, aborting (keeping existing channel= in $HOSTAPD_CONF)"
    postflight
    exit 2
fi

get_chanim_wl || true   # best-effort, ignore failure

log "scan data source: $SOURCE, scoring channels for band $BAND..."
ranked="$(score_channels)"
log "ranked channels (channel score, lower is better):"
echo "$ranked" | while read -r c s; do log "  $c -> $s"; done

best_channel="$(echo "$ranked" | head -n1 | awk '{print $1}')"

if [ -z "$best_channel" ]; then
    log "scoring produced no candidate channel, aborting"
    postflight
    exit 2
fi

# Hysteresis: don't bounce the AP to a new channel just because this run's
# snapshot happened to score it marginally better. Real-hardware testing
# showed the ranking can swing a lot between two runs seconds apart (see
# HYSTERESIS_MARGIN_PCT comments near the top of this file for the
# suspected cause) - only switch if the new candidate is a CLEAR
# improvement over whatever channel is already configured, not just
# nominally top of this run's list.
if [ "$HYSTERESIS_MARGIN_PCT" -gt 0 ] && [ -n "$CURRENT_CHANNEL" ] && [ "$best_channel" != "$CURRENT_CHANNEL" ]; then
    current_score="$(echo "$ranked" | awk -v c="$CURRENT_CHANNEL" '$1==c{print $2; exit}')"
    best_score="$(echo "$ranked" | head -n1 | awk '{print $2}')"
    if [ -n "$current_score" ]; then
        keep_current="$(awk -v cur="$current_score" -v best="$best_score" -v m="$HYSTERESIS_MARGIN_PCT" \
            'BEGIN{ threshold = cur * (1 - m/100); print (best <= threshold) ? 0 : 1 }')"
        if [ "$keep_current" -eq 1 ]; then
            log "keeping current channel=$CURRENT_CHANNEL (score $current_score) instead of switching to $best_channel (score $best_score): not at least ${HYSTERESIS_MARGIN_PCT}% better, avoiding an unnecessary channel change (--switch-margin 0 to disable this)"
            best_channel="$CURRENT_CHANNEL"
        else
            log "switching from channel=$CURRENT_CHANNEL (score $current_score) to $best_channel (score $best_score): at least ${HYSTERESIS_MARGIN_PCT}% better"
        fi
    else
        log "current channel=$CURRENT_CHANNEL wasn't in this run's candidate list (score unknown) - switching to $best_channel since there's no baseline to compare against"
    fi
fi

# Defense-in-depth sanity check: confirm the selected channel is at least
# numerically plausible for the BAND actually used this run, before
# writing it, regardless of which code path produced it. Added after a
# real incident where a band-classification bug (see
# get_candidates_from_wl comments) picked a 2.4GHz channel number under a
# "-b 6" request, wrote it into a hw_mode=a config, and hostapd silently
# refused to start with it.
#
# IMPORTANT: this keys off $BAND (what this run actually resolved to and
# used for candidate derivation/scoring), NOT the conf's hw_mode= alone -
# an earlier version of this check used hw_mode= directly (hw_mode=a
# requires channel >=36), which sounds reasonable but is WRONG for 6GHz:
# hostapd has no separate hw_mode for 6GHz, so a 6GHz AP is configured
# with hw_mode=a too, and legitimate 6GHz channel numbers are low (1, 5,
# 9, 13...233 - the same numbering style as 2.4GHz). That first version
# was caught immediately in testing: it refused a *correct* 6GHz
# selection (channel 21) as if it were a bug, because hw_mode=a alone
# can't tell "5GHz, must be >=36" and "6GHz, low numbers are normal"
# apart. Checking against $BAND directly (which already disambiguates
# this) avoids that false positive.
sane=1
case "$BAND" in
    2.4) [ "$best_channel" -ge 1 ] && [ "$best_channel" -le 14 ] || sane=0 ;;
    5)   [ "$best_channel" -ge 36 ] || sane=0 ;;
    6)   ch_mod4=$(( (best_channel - 1) % 4 ))
         { [ "$ch_mod4" -eq 0 ] && [ "$best_channel" -ge 1 ] && [ "$best_channel" -le 233 ]; } || sane=0
         ;;
esac
if [ "$sane" -eq 0 ]; then
    log "REFUSING to write channel=$best_channel: implausible for band $BAND in $HOSTAPD_CONF (this indicates a band-classification bug upstream, not a real scan result - not touching the config)"
    postflight
    exit 2
fi

log "selected channel: $best_channel"
update_hostapd_channel "$best_channel" "$HOSTAPD_CONF"

postflight
exit 0
