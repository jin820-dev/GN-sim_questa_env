from __future__ import annotations

import argparse
import csv
import glob
import os
import re
import sys
from dataclasses import dataclass
from typing import Optional


# --- Regex patterns ---
RE_SCENARIO_1 = re.compile(r"^===\s*Run scenario:\s*(\S+)\s*===", re.MULTILINE)
RE_SCENARIO_2 = re.compile(r"^\s*SCENARIO\s*[:=]\s*(\S+)\s*$", re.MULTILINE)
RE_SEED_1     = re.compile(r"^\s*SEED\s*[:=]\s*(\d+)\s*$", re.MULTILINE)

# New: TEST result tag (preferred)
# Examples:
#   # [TEST] RESULT=PASS
#   # [TEST] RESULT=FAIL errors=3
RE_TEST_PASS_LINE = re.compile(r"\[TEST\].*\bRESULT\s*=\s*PASS\b", re.IGNORECASE)
RE_TEST_FAIL_LINE = re.compile(r"\[TEST\].*\bRESULT\s*=\s*FAIL\b", re.IGNORECASE)

# Existing: SCB result line (fallback)
RE_SCB_PASS_LINE = re.compile(r"\[SCB\].*TEST\s+PASSED", re.IGNORECASE)
RE_SCB_FAIL_LINE = re.compile(r"\[SCB\].*TEST\s+FAILED", re.IGNORECASE)

# Key-value extraction (from result line)
RE_TRANSFERS   = re.compile(r"\btransfers\s*=\s*(\d+)\b", re.IGNORECASE)
RE_ERRORS_KV   = re.compile(r"\berrors\s*=\s*(\d+)\b", re.IGNORECASE)
RE_IN_KV       = re.compile(r"\bin\s*=\s*(\d+)\b", re.IGNORECASE)
RE_OUT_KV      = re.compile(r"\bout\s*=\s*(\d+)\b", re.IGNORECASE)
RE_PENDING_KV  = re.compile(r"\bpending\s*=\s*(\d+)\b", re.IGNORECASE)

# Final Questa summary lines (may appear multiple times; take the last one)
RE_FINAL_ERRWARN = re.compile(r"^#\s*Errors:\s*(\d+),\s*Warnings:\s*(\d+)\s*$", re.MULTILINE)


@dataclass
class TestSummary:
    logfile: str
    scenario: str
    seed: Optional[int]
    result: str  # PASS/FAIL/UNKNOWN
    transfers: Optional[int]
    errors: Optional[int]       # from tag line (TEST/SCB), if available
    questa_errors: Optional[int]
    questa_warnings: Optional[int]
    result_source: str          # TEST/SCB/QUESTA/UNKNOWN
    result_line: str            # extracted line for traceability


def read_text_auto(path: str) -> str:
    """Read text with BOM/heuristics (handles PowerShell Tee-Object UTF-16 logs)."""
    with open(path, "rb") as f:
        b = f.read()

    if b.startswith(b"\xff\xfe"):
        return b.decode("utf-16-le", errors="ignore")
    if b.startswith(b"\xfe\xff"):
        return b.decode("utf-16-be", errors="ignore")
    if b.startswith(b"\xef\xbb\xbf"):
        return b.decode("utf-8-sig", errors="ignore")

    if b.count(b"\x00") > len(b) // 10:
        try:
            return b.decode("utf-16-le", errors="ignore")
        except Exception:
            pass

    try:
        return b.decode("utf-8", errors="ignore")
    except Exception:
        return b.decode("cp932", errors="ignore")


def _first_match_int(rx: re.Pattern, text: str) -> Optional[int]:
    m = rx.search(text)
    return int(m.group(1)) if m else None


def _last_match_int_pair(rx: re.Pattern, text: str) -> tuple[Optional[int], Optional[int]]:
    last = None
    for m in rx.finditer(text):
        last = m
    if not last:
        return None, None
    return int(last.group(1)), int(last.group(2))


def _find_last_result_line(text: str) -> tuple[str, str, str]:
    """
    Decide result with priority:
      1) [TEST] RESULT=...
      2) [SCB] TEST PASSED/FAILED
      3) Questa final Errors count (heuristic)
    Returns: (result, source, line)
      result: PASS/FAIL/UNKNOWN
      source: TEST/SCB/QUESTA/UNKNOWN
      line  : the matched line (or empty)
    """
    last_test_pass = None
    last_test_fail = None
    last_scb_pass = None
    last_scb_fail = None

    lines = text.splitlines()

    for line in lines:
        if "[TEST]" in line:
            if RE_TEST_PASS_LINE.search(line):
                last_test_pass = line
            if RE_TEST_FAIL_LINE.search(line):
                last_test_fail = line

        if "[SCB]" in line:
            if RE_SCB_PASS_LINE.search(line):
                last_scb_pass = line
            if RE_SCB_FAIL_LINE.search(line):
                last_scb_fail = line

    # Priority 1: TEST tag
    if last_test_fail is not None:
        return "FAIL", "TEST", last_test_fail
    if last_test_pass is not None:
        return "PASS", "TEST", last_test_pass

    # Priority 2: SCB
    if last_scb_fail is not None:
        return "FAIL", "SCB", last_scb_fail
    if last_scb_pass is not None:
        return "PASS", "SCB", last_scb_pass

    # Priority 3: Questa errors heuristic (if present)
    q_err, _q_warn = _last_match_int_pair(RE_FINAL_ERRWARN, text)
    if q_err is not None:
        if q_err > 0:
            return "FAIL", "QUESTA", f"# Errors: {q_err} (heuristic)"
        else:
            # NOTE: This does NOT guarantee functional correctness,
            # but for "no-scoreboard/no-assert" smoke tests it's reasonable.
            return "PASS", "QUESTA", f"# Errors: {q_err} (heuristic)"

    return "UNKNOWN", "UNKNOWN", ""


def parse_one_log(path: str) -> TestSummary:
    text = read_text_auto(path)

    # scenario
    m = RE_SCENARIO_1.search(text)
    if m:
        scenario = m.group(1)
    else:
        m2 = RE_SCENARIO_2.search(text)
        scenario = m2.group(1) if m2 else os.path.splitext(os.path.basename(path))[0]

    # seed
    seed = _first_match_int(RE_SEED_1, text)

    # final Questa errors/warnings
    q_err, q_warn = _last_match_int_pair(RE_FINAL_ERRWARN, text)

    # result
    result, source, line = _find_last_result_line(text)

    # Hard rule: Questa reported Errors > 0 => FAIL (SVA/assert/fatal/etc.)
    if q_err is not None and q_err > 0:
        # If user explicitly marked PASS, still fail (environment error)
        if result != "FAIL":
            result = "FAIL"
            source = "QUESTA"
            line = f"# Errors: {q_err}, Warnings: {q_warn} (override)"

    # optional numbers from the chosen result line
    transfers = _first_match_int(RE_TRANSFERS, line) if line else None
    errors = _first_match_int(RE_ERRORS_KV, line) if line else None

    return TestSummary(
        logfile=path,
        scenario=scenario,
        seed=seed,
        result=result,
        transfers=transfers,
        errors=errors,
        questa_errors=q_err,
        questa_warnings=q_warn,
        result_source=source,
        result_line=line,
    )


def find_logs(patterns: list[str]) -> list[str]:
    paths: list[str] = []
    for pat in patterns:
        paths.extend(glob.glob(pat))
    return sorted(set(paths))


def print_table(rows: list[TestSummary]) -> None:
    def s(x) -> str:
        return "" if x is None else str(x)

    headers = ["SCENARIO", "RESULT", "SRC", "SEED", "TRANSFERS", "ERRS", "Q_ERR", "Q_WARN", "LOG"]
    colw = [20, 8, 6, 6, 10, 6, 6, 6, 0]

    def fmt_row(cols: list[str]) -> str:
        out = []
        for i, c in enumerate(cols):
            if i < len(colw) - 1:
                out.append(c[:colw[i]].ljust(colw[i]))
            else:
                out.append(c)
        return " ".join(out)

    print("=== SUMMARY ===")
    print(fmt_row(headers))
    print("-" * 120)
    for r in rows:
        print(fmt_row([
            r.scenario,
            r.result,
            r.result_source,
            s(r.seed),
            s(r.transfers),
            s(r.errors),
            s(r.questa_errors),
            s(r.questa_warnings),
            r.logfile,
        ]))
    print("-" * 120)

    total = len(rows)
    n_pass = sum(r.result == "PASS" for r in rows)
    n_fail = sum(r.result == "FAIL" for r in rows)
    n_unk = sum(r.result == "UNKNOWN" for r in rows)
    print(f"TOTAL={total}  PASS={n_pass}  FAIL={n_fail}  UNKNOWN={n_unk}")


def write_csv(rows: list[TestSummary], out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "scenario", "result", "result_source", "seed", "transfers", "errors",
            "questa_errors", "questa_warnings",
            "logfile", "result_line"
        ])
        for r in rows:
            w.writerow([
                r.scenario, r.result, r.result_source, r.seed, r.transfers, r.errors,
                r.questa_errors, r.questa_warnings,
                r.logfile, r.result_line
            ])


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        description="Summarize Questa/ModelSim test logs per scenario and exit with pass/fail."
    )
    ap.add_argument(
        "log_patterns",
        nargs="*",
        default=["result/log/**/*.log", "result/log/*.log", "log/**/*.log", "log/*.log"],
        help="Glob patterns for log files (default: common log folders).",
    )
    ap.add_argument(
        "--csv",
        default="result/summary.csv",
        help="Write CSV summary to this path (default: result/summary.csv).",
    )
    ap.add_argument(
        "--allow-unknown",
        action="store_true",
        help="Do not fail if a log has UNKNOWN result.",
    )
    ap.add_argument(
        "--debug-lines",
        action="store_true",
        help="Print the extracted result line per scenario.",
    )
    args = ap.parse_args(argv)

    paths = find_logs(args.log_patterns)
    if not paths:
        print(f"ERROR: No logs found. Patterns: {args.log_patterns}")
        return 2

    rows = [parse_one_log(p) for p in paths]

    print_table(rows)
    write_csv(rows, args.csv)
    print(f"CSV written: {args.csv}")

    if args.debug_lines:
        print("\n=== DEBUG: RESULT LINE ===")
        for r in rows:
            print(f"{r.scenario} ({r.result_source}): {r.result_line}")

    any_fail = any(r.result == "FAIL" for r in rows)
    any_unk = any(r.result == "UNKNOWN" for r in rows)

    if any_fail:
        return 1
    if any_unk and not args.allow_unknown:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
