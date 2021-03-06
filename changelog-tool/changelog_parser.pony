use "peg"

primitive ChangelogParser
  fun apply(): Parser val =>
    recover
      (head() * release(false).opt() * release().many()).eof()
    end

  fun head(): Parser val =>
    recover
      let para = not L("#") * (not L("\n") * Unicode).many1().term()
      -L("# Change Log\n\n") * para.opt() * -L("\n").many()
    end

  fun release(released: Bool = true): Parser val =>
    recover
      let heading =
        if not released then
          L("## [unreleased] - unreleased").term()
        else
          (L("## [") * version() * L("] - ") * date()).term()
        end

      (heading * -L("\n").many1()
        * section(Fixed, released).opt()
        * section(Added, released).opt()
        * section(Changed, released).opt()).node(TRelease)
    end

  fun section(s: TSection, released: Bool): Parser val =>
    recover
      let heading = (L("### ") * L(s.text())).term(s)
      let entries' =
        if released then entries()
        // allow empty sections in unreleased
        else entries().opt()
        end
      (heading * -L("\n").many() * entries').node(NoLabel)
    end

  fun version(): Parser val =>
    recover
      let frac = L(".") * digits()
      (digits() * frac * frac.opt()).term(TVersion)
    end

  fun date(): Parser val =>
    recover
      let digits4 = digit() * digit() * digit() * digit()
      let digits2 = digit() * digit()
      (digits4 * L("-") * digits2 * L("-") * digits2).term(TDate)
    end

  fun entries(): Parser val =>
    recover
      let bullet = L("-") / L("*")
      let line = Forward
      line() = L("\n") / (Unicode * line)
      let sep = bullet / L("#") / L("\n")
      let entry = bullet * L(" ") * line * (not sep * line).many()
      (entry.term(TEntry) * -L("\n").many()).many1().node(TEntries)
    end

  fun digits(): Parser val => recover digit().many1() end

  fun digit(): Parser val => recover R('0', '9') end

trait val TSection is Label
primitive Fixed is TSection fun text(): String => "Fixed"
primitive Added is TSection fun text(): String => "Added"
primitive Changed is TSection fun text(): String => "Changed"

primitive TRelease is Label fun text(): String => "Release"
primitive TVersion is Label fun text(): String => "Version"
primitive TDate is Label fun text(): String => "Date"
primitive TEntries is Label fun text(): String => "Entries"
primitive TEntry is Label fun text(): String => "Entry"
