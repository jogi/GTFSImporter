import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(gtfs_importerTests.allTests),
    ]
}
#endif
