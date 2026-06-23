(* tzdb.sig — IANA timezone offsets from compiled rules. *)

signature TZDB =
sig
  type zone = string
  type instant = { year : int, month : int, day : int, hour : int, minute : int }

  val offsetMinutes : zone -> instant -> int
  val utcOffset : zone -> instant -> string
end
