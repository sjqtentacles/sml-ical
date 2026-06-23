structure Ical :> ICAL =
struct
  type vevent = { dtstart : string, rrule : string option, summary : string }

  fun lines s = String.tokens (fn c => c = #"\n") s

  fun getLine s key =
    let val pref = key ^ ":"
    in case List.find (fn line => String.isPrefix pref line) (lines s) of
         NONE => "" | SOME line => String.substring (line, String.size pref, String.size line - String.size pref)
    end

  fun parseVEvent s =
    { dtstart = getLine s "DTSTART"
    , rrule = if List.exists (fn l => String.isPrefix "RRULE:" l) (lines s) then SOME (getLine s "RRULE") else NONE
    , summary = getLine s "SUMMARY" }

  (* ---- RRULE expansion -------------------------------------------------- *)

  (* Look up "KEY=value" inside a ';'-separated RRULE body. *)
  fun rruleParam rrule key =
    let
      val parts = String.tokens (fn c => c = #";") rrule
      val pref  = key ^ "="
    in
      case List.find (fn p => String.isPrefix pref p) parts of
          SOME p => SOME (String.extract (p, String.size pref, NONE))
        | NONE => NONE
    end

  fun isLeap y = (y mod 4 = 0 andalso y mod 100 <> 0) orelse y mod 400 = 0

  fun daysInMonth (y, m) =
    case m of
        1 => 31 | 2 => (if isLeap y then 29 else 28) | 3 => 31 | 4 => 30
      | 5 => 31 | 6 => 30 | 7 => 31 | 8 => 31 | 9 => 30 | 10 => 31
      | 11 => 30 | 12 => 31 | _ => raise Fail "bad month"

  (* Advance (y,m,d) by one day, rolling month/year over. *)
  fun nextDay (y, m, d) =
    if d < daysInMonth (y, m) then (y, m, d + 1)
    else if m < 12 then (y, m + 1, 1)
    else (y + 1, 1, 1)

  fun addDays ymd 0 = ymd
    | addDays ymd k = addDays (nextDay ymd) (k - 1)

  (* Advance by one month, clamping the day to the target month's length. *)
  fun nextMonth (y, m, d) =
    let val (y', m') = if m < 12 then (y, m + 1) else (y + 1, 1)
        val dim = daysInMonth (y', m')
    in (y', m', Int.min (d, dim)) end

  fun addMonths ymd 0 = ymd
    | addMonths ymd k = addMonths (nextMonth ymd) (k - 1)

  (* Advance one year, clamping Feb-29 to Feb-28 in non-leap years. *)
  fun addYears (y, m, d) k =
    let val y' = y + k
        val dim = daysInMonth (y', m)
    in (y', m, Int.min (d, dim)) end

  (* Parse the leading "YYYYMMDD" of a DTSTART value; keep the remainder
     (e.g. "T120000Z") so it can be re-attached unchanged. *)
  fun splitDate s =
    if String.size s < 8 then raise Fail "DTSTART too short"
    else
      let
        fun n a b = case Int.fromString (String.substring (s, a, b)) of
                        SOME v => v | NONE => raise Fail "bad DTSTART digits"
        val y = n 0 4 and m = n 4 2 and d = n 6 2
        val suffix = String.extract (s, 8, NONE)
      in ((y, m, d), suffix) end

  fun pad2 n = if n < 10 then "0" ^ Int.toString n else Int.toString n
  fun pad4 n =
    let val s = Int.toString n in
      if n < 10 then "000" ^ s else if n < 100 then "00" ^ s
      else if n < 1000 then "0" ^ s else s
    end

  fun fmt ((y, m, d), suffix) = pad4 y ^ pad2 m ^ pad2 d ^ suffix

  (* Expand the n occurrences of an event's recurrence rule, returning the
     DTSTART value of each occurrence.  Supports FREQ = DAILY | WEEKLY |
     MONTHLY | YEARLY with an optional INTERVAL (default 1).  Occurrence 0 is
     DTSTART itself.  With no RRULE, only the single DTSTART is returned. *)
  fun expandRRuleCount ({ dtstart, rrule, ... } : vevent) n =
    let
      val (ymd0, suffix) = splitDate dtstart
    in
      case rrule of
          NONE => [fmt (ymd0, suffix)]
        | SOME r =>
            let
              val freq = Option.getOpt (rruleParam r "FREQ", "DAILY")
              val interval =
                case rruleParam r "INTERVAL" of
                    SOME s => (case Int.fromString s of SOME v => v | NONE => 1)
                  | NONE => 1
              val stepFn =
                case freq of
                    "DAILY"   => (fn ymd => addDays ymd interval)
                  | "WEEKLY"  => (fn ymd => addDays ymd (7 * interval))
                  | "MONTHLY" => (fn ymd => addMonths ymd interval)
                  | "YEARLY"  => (fn ymd => addYears ymd interval)
                  | _ => raise Fail ("unsupported FREQ: " ^ freq)
              fun gen 0 _ acc = List.rev acc
                | gen k ymd acc = gen (k - 1) (stepFn ymd) (fmt (ymd, suffix) :: acc)
            in
              if n <= 0 then [] else gen n ymd0 []
            end
    end
end
