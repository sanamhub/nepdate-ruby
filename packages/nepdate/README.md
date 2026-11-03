# nepdate

Bikram Sambat (Nepali calendar) dates for Ruby: conversion to and from Gregorian, arithmetic with
clamp and spill, formatting and parsing in English and Nepali, inclusive ranges and fiscal years.
Pure Ruby, Ruby 3.4 or newer, no runtime dependency.

```ruby
require "nepdate"

date = NepDate::Date.from_bs(2081, 4, 15)
puts date                   # 2081/04/15
puts date.to_date           # 2024-07-30
puts date.to_long_string(weekday: true)
```

`nepdate-patro` adds tithi, public holidays and events. The full API is in the repository's
[docs/API.md](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md). Part of the NepDate
family; the data and behaviour come from the hub
[`sanamhub/nepdate`](https://github.com/sanamhub/nepdate) and the C# original
[NepDate](https://github.com/RajuPrasai/NepDate).
