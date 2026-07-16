import XCTest
@testable import Flowtear

// The plan-window math behind the schedule's day checkboxes. Every plan day
// must map to a real calendar date in EVERY state — a nil (or a "future days
// don't count" guard) is exactly what once left whole plans' checkboxes dead.
final class StretchPlanTests: XCTestCase {
    let cal = Calendar(identifier: .gregorian)

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    // Anchored: the 14-day window ends the day before the predicted period.
    func testFullWindowEndsDayBeforePeriod() {
        let next = day(2026, 8, 1)
        XCTAssertEqual(StretchPlan.date(forPlanDay: 1, tier: .full,
                                        nextPeriodStart: next, today: day(2026, 7, 16), cal: cal),
                       day(2026, 7, 18))
        XCTAssertEqual(StretchPlan.date(forPlanDay: 14, tier: .full,
                                        nextPeriodStart: next, today: day(2026, 7, 16), cal: cal),
                       day(2026, 7, 31))
    }

    func testStarterWindowIsThreeDaysBeforePeriod() {
        let next = day(2026, 8, 1)
        XCTAssertEqual(StretchPlan.date(forPlanDay: 1, tier: .starter,
                                        nextPeriodStart: next, today: day(2026, 7, 16), cal: cal),
                       day(2026, 7, 29))
        XCTAssertEqual(StretchPlan.date(forPlanDay: 3, tier: .starter,
                                        nextPeriodStart: next, today: day(2026, 7, 16), cal: cal),
                       day(2026, 7, 31))
    }

    // The regression that broke the checkboxes: with no prediction, every day
    // must STILL have a date (fallback window starts today).
    func testEveryPlanDayHasADateWithoutPrediction() {
        for tier in [StretchTier.starter, .full] {
            for d in 1...tier.totalDays {
                XCTAssertNotNil(StretchPlan.date(forPlanDay: d, tier: tier,
                                                 nextPeriodStart: nil,
                                                 today: day(2026, 7, 16), cal: cal),
                                "plan day \(d) of \(tier.label) lost its date")
            }
        }
    }

    func testFallbackWindowStartsToday() {
        XCTAssertEqual(StretchPlan.date(forPlanDay: 1, tier: .full,
                                        nextPeriodStart: nil, today: day(2026, 7, 16), cal: cal),
                       day(2026, 7, 16))
        XCTAssertEqual(StretchPlan.date(forPlanDay: 14, tier: .full,
                                        nextPeriodStart: nil, today: day(2026, 7, 16), cal: cal),
                       day(2026, 7, 29))
    }

    // In fallback mode nothing is ever "missed" — no day precedes today, so
    // the lock-in penalty loop (which only charges dates before today) is inert.
    func testFallbackWindowNeverPrecedesToday() {
        let today = day(2026, 7, 16)
        for tier in [StretchTier.starter, .full] {
            for d in 1...tier.totalDays {
                let date = StretchPlan.date(forPlanDay: d, tier: tier,
                                            nextPeriodStart: nil, today: today, cal: cal)!
                XCTAssertGreaterThanOrEqual(date, today)
            }
        }
    }

    // Prediction must ignore time-of-day: 14:30 on Jul 13 is still 16 calendar
    // days before Jul 29, not 15. The schedule's "today" row maps through
    // daysUntilNextPeriod, so a truncation here would silently shift which
    // date the badged row's checkbox writes to.
    func testDaysUntilNextPeriodCountsCalendarDays() {
        let afternoon = cal.date(from: DateComponents(year: 2026, month: 7, day: 13,
                                                      hour: 14, minute: 30))!
        let periodDays = (1...4).map { day(2026, 7, $0) }
        let p = CycleEngine.predict(periodDays: periodDays, today: afternoon,
                                    settings: CycleSettings(), cal: cal)
        XCTAssertEqual(p.nextPeriodStart, day(2026, 7, 29))
        XCTAssertEqual(p.daysUntilNextPeriod, 16)
    }

    // planDay / session round-trips: the schedule labels and the per-day
    // sessions must agree for both tiers.
    func testPlanDayRoundTrips() {
        for tier in [StretchTier.starter, .full] {
            for session in StretchPlan.days(for: tier) {
                let n = StretchPlan.planDay(session, tier: tier)
                XCTAssertTrue((1...tier.totalDays).contains(n))
                XCTAssertEqual(StretchPlan.session(daysUntilPeriod: session.daysBeforePeriod,
                                                   tier: tier)?.daysBeforePeriod,
                               session.daysBeforePeriod)
            }
            // Day numbers are exactly 1...totalDays, each exactly once.
            let numbers = StretchPlan.days(for: tier).map { StretchPlan.planDay($0, tier: tier) }.sorted()
            XCTAssertEqual(numbers, Array(1...tier.totalDays))
        }
    }
}
