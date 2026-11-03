# nepdate-patro

The patro (पात्रो, the Nepali almanac) for Ruby: tithi, public holidays and events for Bikram Sambat
dates. It depends on `nepdate`; the core gem has no almanac data.

```ruby
require "nepdate"
require "nepdate/patro"

day = NepDate::Patro.info(NepDate::Date.from_bs(2081, 2, 15))
puts day.tithi.english  # Panchami
puts day.public_holiday? # true
puts day.events_en       # Republic Day
```

The data covers BS 2077-01-01 to 2084-08-20 and is informational, not an official calendar. It is
compiled into constant tables, so nothing is read at run time. The full API is in the repository's
[docs/API.md](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md).
