import XCTest
@testable import Flowtear

// BasalTemp converts between stored Celsius and whatever unit her region
// reads. A wrong conversion writes a wrong temperature into her log and the
// chart never says so, which is why the round trip gets a test. Locale is a
// static let, so these assert the invariants that must hold in EITHER unit.
final class BasalTempTests: XCTestCase {

    // What she slides to is what comes back out.
    func testDisplayAndCelsiusAreInverses() {
        for c in stride(from: 35.0, through: 38.0, by: 0.1) {
            let back = BasalTemp.celsius(fromDisplay: BasalTemp.display(c))
            XCTAssertEqual(back, c, accuracy: 1e-9)
        }
    }

    // The slider's bounds are the same physical span in either unit:
    // 96–100 °F is 35.56–37.78 °C.
    func testSliderRangeCoversTheSamePhysicalSpan() {
        let lo = BasalTemp.celsius(fromDisplay: BasalTemp.range.lowerBound)
        let hi = BasalTemp.celsius(fromDisplay: BasalTemp.range.upperBound)
        XCTAssertEqual(lo, 35.6, accuracy: 0.1)
        XCTAssertEqual(hi, 37.8, accuracy: 0.1)
    }

    // The seed value is inside the slider, or the first drag jumps.
    func testTypicalReadingSitsInsideTheRange() {
        XCTAssertTrue(BasalTemp.range.contains(BasalTemp.typicalDisplay))
        XCTAssertEqual(BasalTemp.display(BasalTemp.typicalCelsius),
                       BasalTemp.typicalDisplay, accuracy: 1e-9)
    }

    // Two decimals, and the unit label agrees with the mode.
    func testTextAndUnitAgree() {
        let c = BasalTemp.typicalCelsius
        XCTAssertEqual(BasalTemp.text(c), String(format: "%.2f", BasalTemp.display(c)))
        XCTAssertEqual(BasalTemp.unit, BasalTemp.usesCelsius ? "°C" : "°F")
        XCTAssertEqual(BasalTemp.labelled(c), "\(BasalTemp.text(c)) \(BasalTemp.unit)")
    }
}
