//
//  CodeChallengeUITests.swift
//  CodeChallengeUITests
//
//  Created by Marcelo Gobetti on 4/19/18.
//

import XCTest

class CodeChallengeUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    func testCellClickOpensDetailsPage() {
        firstVisibleCell.tap()
        XCTAssertTrue(app.otherElements["detailsView"].exists)
    }
    
    func testNavigationBarAppearsOnDetailsPageAfterScrollingDownAndUp() {
        firstVisibleCell.tap()
        let scrollView = app/*@START_MENU_TOKEN@*/.scrollViews/*[[".otherElements[\"detailsView\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element
        scrollView.swipeUp()
        scrollView.swipeDown()
        XCTAssertTrue(app.navigationBars.firstMatch.buttons["Back"].exists)
    }
    
    func testNavigationBarDisappearsComingBackFromDetailsPageIfPreviouslyHidden() {
        firstVisibleCell.swipeUp()
        XCTAssertFalse(app.navigationBars.firstMatch.exists,
                       "The navigation bar should auto hide on swipe")
        
        // Details page:
        firstVisibleCell.swipeDown()
        firstVisibleCell.tap()
        app.navigationBars.firstMatch.buttons["Back"].firstMatch.tap()
        
        // List page:
        firstVisibleCell.swipeUp()
        XCTAssertFalse(app.navigationBars.firstMatch.exists,
                       "The navigation bar should auto hide again on swipe")
    }
    
    func testScrollToBottomLoadsMoreItems() {
        let previousCellsCount = app.collectionViews.cells.count
        
        firstVisibleCell.swipeUp()
        XCTAssertGreaterThan(app.collectionViews.cells.count, previousCellsCount)
    }
    
    func testDeviceRotationRecalculatesCellSizes() {
        let cellWidthOnPortrait = firstVisibleCell.frame.size.width
        
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertGreaterThan(firstVisibleCell.frame.size.width, cellWidthOnPortrait)
    }
    
    func testNonEmptySearchReplacesResults() {
        let firstCell = firstVisibleCell
        let firstCellTitleWhenNotSearching = firstCell.staticTexts.firstMatch.label
        
        firstCell.swipeDown()
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("some text")
        
        let differs = NSPredicate(format: "staticTexts.firstMatch.label != %@", firstCellTitleWhenNotSearching)
        expectation(for: differs, evaluatedWith: firstVisibleCell, handler: nil)
        waitForExpectations(timeout: 2.0)
        
        searchField.buttons["Clear text"].tap()
        
        let equals = NSPredicate(format: "staticTexts.firstMatch.label == %@", firstCellTitleWhenNotSearching)
        expectation(for: equals, evaluatedWith: firstVisibleCell, handler: nil)
        waitForExpectations(timeout: 2.0)
    }
    
    private var firstVisibleCell: XCUIElement {
        return app.collectionViews.cells.otherElements.firstMatch
    }
}
