import XCTest
@testable import Flowtear

// The prediction math is the one non-trivial logic path — cover it end to end.
final class CycleEngineTests: XCTestCase {
    let cal = Calendar(identifier: .gregorian)

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testNoHistoryHasNoPrediction() {
        let p = CycleEngine.predict(periodDays: [], today: day(2026, 7, 13),
                                    settings: CycleSettings(), cal: cal)
        XCTAssertFalse(p.hasHistory)
        XCTAssertNil(p.nextPeriodStart)
        XCTAssertEqual(p.averageCycleLength, 28)   // falls back to default
    }

    func testSinglePeriodUsesDefaultCycle() {
        // 4-day period starting Jul 1; today is Jul 13 → cycle day 13.
        let days = (1...4).map { day(2026, 7, $0) }
        let p = CycleEngine.predict(periodDays: days, today: day(2026, 7, 13),
                                    settings: CycleSettings(), cal: cal)
        XCTAssertEqual(p.cycleDay, 13)
        XCTAssertEqual(p.averageCycleLength, 28)
        XCTAssertEqual(p.nextPeriodStart, day(2026, 7, 29))          // Jul 1 + 28
        XCTAssertEqual(p.ovulationDate, day(2026, 7, 15))            // next − 14 luteal
        XCTAssertEqual(p.daysUntilNextPeriod, 16)
    }

    func testAverageAcrossRegularCycles() {
        // Starts Jun 1, Jun 29, Jul 27 → gaps of 28 → avg 28.
        var days: [Date] = []
        for start in [day(2026, 6, 1), day(2026, 6, 29), day(2026, 7, 27)] {
            for off in 0..<4 { days.append(cal.date(byAdding: .day, value: off, to: start)!) }
        }
        let starts = CycleEngine.periodStarts(from: days, cal: cal)
        XCTAssertEqual(starts.count, 3)
        XCTAssertEqual(CycleEngine.averageCycleLength(starts: starts, fallback: 30, cal: cal), 28)
    }

    func testIrregularCyclesAverage() {
        // Gaps of 26 and 32 → avg 29.
        let starts = [day(2026, 5, 1), day(2026, 5, 27), day(2026, 6, 28)]
        XCTAssertEqual(CycleEngine.averageCycleLength(starts: starts, fallback: 28, cal: cal), 29)
    }

    func testPhaseIsMenstrualDuringPeriod() {
        let days = (1...5).map { day(2026, 7, $0) }
        let p = CycleEngine.predict(periodDays: days, today: day(2026, 7, 3),
                                    settings: CycleSettings(), cal: cal)
        XCTAssertEqual(p.phase, .menstrual)
    }

    func testGapSplitsIntoSeparatePeriods() {
        // Jul 1-3 then Jul 20-22: two periods, not one.
        let days = [1, 2, 3, 20, 21, 22].map { day(2026, 7, $0) }
        XCTAssertEqual(CycleEngine.periodStarts(from: days, cal: cal).count, 2)
    }
}
