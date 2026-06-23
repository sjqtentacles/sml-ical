signature ICAL =
sig
  type vevent = { dtstart : string, rrule : string option, summary : string }

  (* Parse a single VEVENT block (DTSTART / RRULE / SUMMARY lines). *)
  val parseVEvent : string -> vevent

  (* Expand the first `n` occurrences of an event's recurrence rule, returning
     each occurrence's DTSTART value.  Supports FREQ = DAILY|WEEKLY|MONTHLY|
     YEARLY with optional INTERVAL.  Occurrence 0 is DTSTART itself; with no
     RRULE the singleton [DTSTART] is returned. *)
  val expandRRuleCount : vevent -> int -> string list
end
