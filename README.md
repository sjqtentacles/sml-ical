# sml-ical

[![CI](https://github.com/sjqtentacles/sml-ical/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-ical/actions/workflows/ci.yml)

iCalendar (RFC 5545) **VEVENT** parsing and recurrence-rule expansion for
Standard ML. Parses the core date/recurrence/summary fields of an event and
expands its `RRULE` into concrete occurrence dates using real calendar
arithmetic (leap years, month-length clamping).

## API

```sml
type vevent = { dtstart : string, rrule : string option, summary : string }

Ical.parseVEvent block          (* read DTSTART / RRULE / SUMMARY lines *)
Ical.expandRRuleCount ev n      (* first n occurrence DTSTART values *)
```

`expandRRuleCount` supports `FREQ = DAILY | WEEKLY | MONTHLY | YEARLY` with an
optional `INTERVAL`. Occurrence 0 is `DTSTART` itself; with no `RRULE` the
singleton `[DTSTART]` is returned. Dates are produced as `YYYYMMDD` strings with
correct rollover:

```sml
val ev = Ical.parseVEvent "DTSTART:20240228\nRRULE:FREQ=DAILY"
Ical.expandRRuleCount ev 3   (* ["20240228","20240229","20240301"] — 2024 is a leap year *)
```

## Scope and limitations

- Recurrence covers `FREQ` + `INTERVAL` only. `COUNT`, `UNTIL`, `BYDAY`,
  `BYMONTHDAY`, `BYSETPOS` and other `BY*` parts are **not** evaluated.
- Dates are treated as `YYYYMMDD` (date-only). Times, time zones (`TZID`),
  and `DTEND`/`DURATION` are not modelled.
- `MONTHLY`/`YEARLY` clamp to the last valid day of the target month (e.g.
  Jan 31 + 1 month → Feb 28/29).
- Single-event parsing; `VCALENDAR` wrappers, folding of long lines, and
  multiple components are out of scope.

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-ical
smlpkg sync
```

Reference from your `.mlb`:

```
lib/github.com/sjqtentacles/sml-ical/ical.mlb
```

## Building and testing

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make clean
```

## Project layout

```
sml.pkg
Makefile
lib/github.com/sjqtentacles/sml-ical/
  ical.sig
  ical.sml     VEVENT parse + RRULE date arithmetic
  ical.mlb
test/
  test.sml     parse, DAILY/WEEKLY/MONTHLY/YEARLY, leap-year rollover, clamping
```

## License

MIT. See [LICENSE](LICENSE).
