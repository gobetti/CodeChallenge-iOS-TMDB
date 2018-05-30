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
        anyCell.tap()
        XCTAssertTrue(app.otherElements["detailsView"].exists)
    }
    
    func testNavigationBarAppearsOnDetailsPageAfterScrollingDownAndUp() {
        anyCell.tap()
        let scrollView = app/*@START_MENU_TOKEN@*/.scrollViews/*[[".otherElements[\"detailsView\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element
        scrollView.swipeUp()
        scrollView.swipeDown()
        XCTAssertTrue(app.navigationBars.firstMatch.buttons["Back"].exists)
    }
    
    func testNavigationBarDisappearsComingBackFromDetailsPageIfPreviouslyHidden() {
        anyCell.swipeUp()
        XCTAssertFalse(app.navigationBars.firstMatch.exists,
                       "The navigation bar should auto hide on swipe")
        
        // Details page:
        anyCell.swipeDown()
        anyCell.tap()
        app.navigationBars.firstMatch.buttons["Back"].firstMatch.tap()
        
        // List page:
        anyCell.swipeUp()
        XCTAssertFalse(app.navigationBars.firstMatch.exists,
                       "The navigation bar should auto hide again on swipe")
    }
    
    func testScrollToBottomLoadsMoreItems() {
        let previousCellsCount = app.collectionViews.cells.count
        
        anyCell.swipeUp()
        XCTAssertGreaterThan(app.collectionViews.cells.count, previousCellsCount)
    }
    
    func testDeviceRotationRecalculatesCellSizes() {
        let cellWidthOnPortrait = anyCell.frame.size.width
        
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertGreaterThan(anyCell.frame.size.width, cellWidthOnPortrait)
    }
    
    func testNonEmptySearchReplacesResults() {
        let anyCellTitleWhenNotSearching = anyCell.staticTexts.firstMatch.label
        
        anyCell.swipeDown()
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("some text")
        
        // That cell should not exist anymore:
        let differs = NSPredicate(format: "staticTexts.firstMatch.label != %@", anyCellTitleWhenNotSearching)
        expectation(for: differs, evaluatedWith: app.collectionViews.cells, handler: nil)
        waitForExpectations(timeout: 2.0)
        
        searchField.buttons["Clear text"].tap()
        
        // That cell should exist back again:
        let equals = NSPredicate(format: "staticTexts.firstMatch.label == %@", anyCellTitleWhenNotSearching)
        expectation(for: equals, evaluatedWith: app.collectionViews.cells, handler: nil)
        waitForExpectations(timeout: 2.0)
    }
    
    private var anyCell: XCUIElement {
        return app.collectionViews.cells.otherElements.firstMatch
    }
}
