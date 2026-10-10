# 🔍 Data Quality Notes

Validation checks run against the provided data after loading. The queries are in [`07_validation_checks.sql`](../sql/phase2-implementation/07_validation_checks.sql).

---

## ✅ Check 1 — Totals are consistent across queries

The grand total of the fact table must match the grand-total row of every aggregation query. A mismatch would mean a join lost or duplicated rows.

| Source | Total waste collected (tons) |
|---|---:|
| `SUM(Wastecollected)` on `FactTrips` | 3,987,925.34 |
| GROUPING SETS grand-total row | 3,987,925.34 |
| ROLLUP grand-total row | 3,987,925.34 |

**Result:** consistent ✔

## ✅ Check 2 — No orphan trips

Every trip references an existing date, station and truck (0 orphans). The foreign keys enforce this at load time; the check documents it explicitly.

## ⚠️ Check 3 — Weekday names in `DimDate` are shifted by one day

Comparing the provided `WeekdayName` with the real calendar day of each `date`:

| dateid | date | WeekdayName in file | Actual weekday |
|---:|---|---|---|
| 1 | 2019-03-09 | Sunday | **Saturday** |
| 2 | 2019-03-10 | Monday | **Sunday** |
| 3 | 2019-03-11 | Tuesday | **Monday** |
| 4 | 2019-03-12 | Wednesday | **Tuesday** |
| 5 | 2019-03-13 | Thursday | **Wednesday** |

**All 350 rows** are off by one day, and the numeric `Weekday` column shifts with them.

**Impact:** any "waste collected per weekday" report built from this dimension would attribute every day's trips to the wrong weekday. Yearly, quarterly, monthly and daily reports are **not** affected, because those columns are correct.

**Handling in this project:** the source data was loaded unchanged, as the course required. The [enhanced edition](../enhanced/README.md) applies the fix below as part of its transform step. The fix is to derive the weekday attributes from the `date` column instead of trusting the source:

```sql
UPDATE DimDate
SET WeekdayName = TRIM(TO_CHAR(date, 'Day')),
    Weekday     = EXTRACT(ISODOW FROM date);   -- 1 = Monday … 7 = Sunday
```

**Lesson:** derived attributes such as weekday, quarter and month name should be calculated from the date itself, not copied from upstream files.
