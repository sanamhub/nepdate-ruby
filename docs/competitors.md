# Competitors

The competitor rule is [BENCHMARK.md section 7](https://github.com/sanamhub/nepdate/blob/main/spec/BENCHMARK.md#7-choosing-competitors).
It has no Ruby row, so this port uses the Packagist floor as the closest registry analogue: **10,000
total downloads**, because RubyGems, like Packagist, is a general package registry and its public API
reports total downloads, not a monthly figure.

The candidates are every RubyGems gem found on 2026-11-03 whose description converts between Bikram
Sambat and Gregorian dates. The searches were `nepali`, `nepali date`, `bikram sambat`,
`nepali calendar`, `bs date` and `patro`; the complete `nepali` result set was read. Gems that format
numbers, transliterate, or convert other calendars were excluded.

## The candidates

| Gem | Version | Total downloads | First release | Latest release | Licence | Source | Verdict |
|---|---|---:|---|---|---|---|---|
| `nepali_date_converter` | 1.0.1 | 8,810 | 2017-06-16 | 2022-01-23 | MIT | [rubygems.org](https://rubygems.org/gems/nepali_date_converter) | Fails the 10,000 minimum and has no release in 36 months; not selected |
| `nepali_calendar` | 1.0.1 | 6,455 | 2015-09-10 | 2015-09-16 | MIT | [rubygems.org](https://rubygems.org/gems/nepali_calendar) | Fails the 10,000 minimum and has no release in 36 months; not selected |
| `english_nepali_date_converter` | 1.0.0 | 4,487 | 2014-01-20 | 2025-09-03 | MIT | [rubygems.org](https://rubygems.org/gems/english_nepali_date_converter) | Fails the 10,000 minimum; not selected |
| `englishnepalidateconverter` | 1.0.0 | 4,089 | 2014-08-20 | 2025-09-03 | MIT | [rubygems.org](https://rubygems.org/gems/englishnepalidateconverter) | Fails the 10,000 minimum; not selected |
| `miti` | 1.0.1 | 3,334 | 2022-10-11 | 2023-07-01 | MIT | [rubygems.org](https://rubygems.org/gems/miti) | Fails the 10,000 minimum and has no release in 36 months; not selected |

The other search hits with more than 10,000 downloads are not date libraries: `akshar` (28,684)
spells numbers in Nepali words, `torupees` (13,977) formats rupees, `nepali_number` (1,338) and
`tonepali` (3,786) format numbers. `mitier` is a wrapper for the MITIE NLP library.

## Result

No candidate passes the usage floor, so no competitor is selected and the benchmark has no Ruby
competitor column. This is the "no mature library to compare" case in BENCHMARK.md section 7. The
five candidates were not padded into the table.

The largest, `nepali_date_converter`, has 8,810 total downloads after nine years and last released
in 2022. The most recently released pair converted one date per call and have no maintained test
suite or calendar range statement. None offers the hub API, ranges, fiscal years or patro data.

## Why no Ruby sibling

The Java port compared itself with the Kotlin port because both run on the JVM and are maintained as
siblings. Ruby has no sibling port and no RubyGems library above the usage floor. The closest
same-kind reference is the Python port: both are interpreted, dynamically typed runtimes with the
same table-driven design, so `docs/benchmarks.md` measures Python in the same session and uses it as
the 1.5x target. Python is not a RubyGems competitor, so it is not in the competitor table and is not
counted by the section 7 rule; C# NepDate remains the family baseline.
