import XCTest
@testable import Flowtear

// The petal economy's money paths: the pose-award ledger must refund exactly
// what was paid (in any toggle order, across tier switches), penalties must
// charge a day at most once ever, and the whole garden must survive a
// backup → restore round trip.
final class RewardsStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // RewardsStore persists to UserDefaults.standard — clear both slots so
        // every test starts from a pristine garden.
        UserDefaults.standard.removeObject(forKey: "flowtear.rewards.v1")
        UserDefaults.standard.removeObject(forKey: "flowtear.rewards.v1.backup")
    }

    // Check two poses on the ×2 plan, switch to ×4, uncheck both: the refunds
    // must be the ×2 amounts actually paid — never the ×4 recomputation.
    func testRevokeRefundsExactlyWhatWasPaidAcrossTierSwitch() {
        let r = RewardsStore()
        let a1 = r.awardPose(dateKey: "2026-07-16", alreadyDone: 0, total: 3, multiplier: 2)
        let a2 = r.awardPose(dateKey: "2026-07-16", alreadyDone: 1, total: 3, multiplier: 2)
        XCTAssertEqual(a1, 30)   // 15 × 2
        XCTAssertEqual(a2, 40)   // (15 + 5) × 2
        XCTAssertEqual(r.balance, 70)

        // Tier switched to ×4 between check and uncheck — refund stays 40 + 30.
        r.revokePose(dateKey: "2026-07-16", remainingDone: 1, total: 3, wasFullDay: false, multiplier: 4)
        XCTAssertEqual(r.balance, 30)
        r.revokePose(dateKey: "2026-07-16", remainingDone: 0, total: 3, wasFullDay: false, multiplier: 4)
        XCTAssertEqual(r.balance, 0)
    }

    // Days checked before the ledger existed have no log entries — revoke must
    // fall back to recomputing from the passed state instead of refunding 0.
    func testRevokeFallsBackToRecomputeWhenLedgerIsEmpty() {
        let r = RewardsStore()
        r.awardPeriodLanding(dateKey: "2026-07-01")   // +5 so there's balance to take
        XCTAssertEqual(r.balance, 5)
        r.revokePose(dateKey: "2026-07-15", remainingDone: 0, total: 3, wasFullDay: false, multiplier: 1)
        XCTAssertEqual(r.balance, 0)   // 15 recomputed, clamped at zero
    }

    // A missed day is charged at most once ever; excusing marks it handled
    // without charging, and blocks any later charge for that day.
    func testPenalizeAndExcuseAreIdempotentPerDay() {
        let r = RewardsStore()
        _ = r.awardPose(dateKey: "2026-07-16", alreadyDone: 0, total: 3, multiplier: 1)  // +15
        XCTAssertTrue(r.penalizeMissedDay("2026-07-10"))
        XCTAssertEqual(r.balance, 10)
        XCTAssertFalse(r.penalizeMissedDay("2026-07-10"))   // already charged
        XCTAssertEqual(r.balance, 10)

        r.excuseMissedDay("2026-07-11")
        XCTAssertEqual(r.balance, 10)                        // excusing never charges
        XCTAssertFalse(r.penalizeMissedDay("2026-07-11"))   // and blocks the charge
        XCTAssertEqual(r.balance, 10)
    }

    // Backup → restore must round-trip the award ledger (so refunds stay exact
    // even after she moves to a new phone).
    func testBackupRestoreRoundTripsThePoseLedger() {
        let r = RewardsStore()
        _ = r.awardPose(dateKey: "2026-07-16", alreadyDone: 0, total: 3, multiplier: 2)
        _ = r.awardPose(dateKey: "2026-07-16", alreadyDone: 1, total: 3, multiplier: 2)
        guard let data = r.backupData() else { return XCTFail("no backup data") }

        let fresh = RewardsStore()
        XCTAssertTrue(fresh.restore(from: data))
        XCTAssertEqual(fresh.balance, 70)
        // The restored ledger refunds the recorded amounts, newest first.
        fresh.revokePose(dateKey: "2026-07-16", remainingDone: 1, total: 3, wasFullDay: false, multiplier: 1)
        XCTAssertEqual(fresh.balance, 30)
    }
}
