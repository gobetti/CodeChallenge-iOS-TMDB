//
//  CodeChallengeUITests.swift
//  CodeChallengeUITests
//
//  Created by Marcelo Gobetti on 4/19/18.
//

import XCTest

class CodeChallengeUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    func testCellClickOpensDetailsPage() {
        let app = XCUIApplication()
        app.collectionViews.cells.otherElements.firstMatch.tap()
        XCTAssertTrue(app.otherElements["detailsView"].exists)
    }
}
