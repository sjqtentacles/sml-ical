structure Tests = struct open Harness structure I = Ical
fun run () = let
  val sample = "BEGIN:VEVENT\nDTSTART:20240101T120000Z\nRRULE:FREQ=DAILY;COUNT=3\nSUMMARY:Daily\nEND:VEVENT\n"
  val ev = I.parseVEvent sample

  val () = section "VEVENT parse"
  val () = checkString "dtstart" ("20240101T120000Z", #dtstart ev)
  val () = checkString "summary" ("Daily", #summary ev)
  val () = checkBool   "has rrule" (true, Option.isSome (#rrule ev))

  val () = section "DAILY expansion (real dates)"
  val occ = I.expandRRuleCount ev 3
  val () = checkInt "3 occurrences" (3, List.length occ)
  val () = checkStringList "daily dates"
             (["20240101T120000Z","20240102T120000Z","20240103T120000Z"], occ)

  val () = section "leap-year rollover"
  (* Feb 28 2024 (leap) -> Feb 29 -> Mar 1 *)
  val febEv = { dtstart = "20240228T000000Z", rrule = SOME "FREQ=DAILY", summary = "" }
  val () = checkStringList "feb 29 appears"
             (["20240228T000000Z","20240229T000000Z","20240301T000000Z"],
              I.expandRRuleCount febEv 3)
  (* Non-leap 2023: Feb 28 -> Mar 1 directly *)
  val feb23 = { dtstart = "20230228T000000Z", rrule = SOME "FREQ=DAILY", summary = "" }
  val () = checkStringList "non-leap skips feb 29"
             (["20230228T000000Z","20230301T000000Z"],
              I.expandRRuleCount feb23 2)

  val () = section "WEEKLY / INTERVAL / MONTHLY / YEARLY"
  val wk = { dtstart = "20240101T000000Z", rrule = SOME "FREQ=WEEKLY", summary = "" }
  val () = checkStringList "weekly +7d"
             (["20240101T000000Z","20240108T000000Z","20240115T000000Z"],
              I.expandRRuleCount wk 3)
  val ev2 = { dtstart = "20240101T000000Z", rrule = SOME "FREQ=DAILY;INTERVAL=2", summary = "" }
  val () = checkStringList "interval=2 daily"
             (["20240101T000000Z","20240103T000000Z","20240105T000000Z"],
              I.expandRRuleCount ev2 3)
  val mo = { dtstart = "20240131T000000Z", rrule = SOME "FREQ=MONTHLY", summary = "" }
  val () = checkStringList "monthly clamps short months"
             (["20240131T000000Z","20240229T000000Z","20240329T000000Z"],
              I.expandRRuleCount mo 3)
  val yr = { dtstart = "20240229T000000Z", rrule = SOME "FREQ=YEARLY", summary = "" }
  val () = checkStringList "yearly clamps leap day"
             (["20240229T000000Z","20250228T000000Z"],
              I.expandRRuleCount yr 2)

  val () = section "no RRULE"
  val noEv = { dtstart = "20240101T000000Z", rrule = NONE, summary = "x" }
  val () = checkStringList "single occurrence" (["20240101T000000Z"], I.expandRRuleCount noEv 5)
in Harness.run () end end
