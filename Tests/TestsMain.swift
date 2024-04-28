import XCTest
import IDDSwiftTests

var tests = [XCTestCaseEntry]()

tests += FileChangeTests.allTests()
tests += IDDSwiftTests.allTests()
XCTMain(tests)
