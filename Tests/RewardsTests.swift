import XCTest
@testable import Flowtear

// The streak bonus is the one bit of rewards math with real edge cases
// (exponential growth must clamp, never overflow) — pin it down.
final class RewardsTests: XCTestCase {
    func testLogStreakBonusDoublesToCap() {
        XCTAssertEqual(RewardsStore.logStreakBonus(1), 5)
        XCTAssertEqual(RewardsStore.logStreakBonus(2), 10)
        XCTAssertEqual(RewardsStore.logStreakBonus(3), 20)
        XCTAssertEqual(RewardsStore.logStreakBonus(4), 40)
        XCTAssertEqual(RewardsStore.logStreakBonus(5), 80)
        XCTAssertEqual(RewardsStore.logStreakBonus(365), 80)   // capped — a year-long streak can't overflow the shift
        XCTAssertEqual(RewardsStore.logStreakBonus(0), 5)      // clamped floor for a fresh start
    }
}
