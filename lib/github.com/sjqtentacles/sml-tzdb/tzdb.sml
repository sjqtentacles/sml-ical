structure TzRules =
struct
  fun isDstEastern inst =
    let val { year, month, day, hour, minute } = inst
    in (month > 3 andalso month < 11)
       orelse (month = 3 andalso day >= 8)
       orelse (month = 11 andalso day < 7) end

  fun offsetEastern inst = if isDstEastern inst then ~240 else ~300

  fun lookup "UTC" _ = 0
    | lookup "America/New_York" inst = offsetEastern inst
    | lookup _ _ = 0
end

structure Tzdb :> TZDB =
struct
  type zone = string
  type instant = { year : int, month : int, day : int, hour : int, minute : int }

  fun offsetMinutes zone inst = TzRules.lookup zone inst

  fun pad2 n = if n < 10 then "0" ^ Int.toString n else Int.toString n

  fun utcOffset zone inst =
    let val m = offsetMinutes zone inst
        val sign = if m >= 0 then "+" else "-"
        val absM = Real.abs (real m)
        val hh = Real.trunc (absM / 60.0)
        val mm = Real.trunc (absM - real hh * 60.0)
    in sign ^ pad2 hh ^ pad2 mm end
end
