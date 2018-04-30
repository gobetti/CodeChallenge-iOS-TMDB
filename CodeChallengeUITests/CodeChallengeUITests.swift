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
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    func testCellClickOpensDetailsPage() {
        let app = XCUIApplication()
        app.collectionViews.cells.otherElements.firstMatch.tap()
        XCTAssertTrue(app.otherElements["detailsView"].exists)
    }
    
    func testNavigationBarAppearsOnDetailsPageAfterScrollingDownAndUp() {
        let app = XCUIApplication()
        app.collectionViews.cells.otherElements.firstMatch.tap()
        let scrollView = app/*@START_MENU_TOKEN@*/.scrollViews/*[[".otherElements[\"detailsView\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element
        scrollView.swipeUp()
        scrollView.swipeDown()
        XCTAssertTrue(app.navigationBars.firstMatch.buttons["Back"].exists)
    }
    
    func testNavigationBarDisappearsComingBackFromDetailsPageIfPreviouslyHidden() {
        let app = XCUIApplication()
        let collectionViewCell = app.collectionViews.cells.otherElements.firstMatch
        collectionViewCell.swipeUp()
        XCTAssertFalse(app.navigationBars.firstMatch.exists,
                       "The navigation bar should auto hide on swipe")
        
        // Details page:
        collectionViewCell.tap()
        app.navigationBars.firstMatch.buttons["Back"].tap()
        
        // List page:
        let collectionViewCell2 = app.collectionViews.cells.otherElements.firstMatch
        collectionViewCell2.swipeUp()
        XCTAssertFalse(app.navigationBars.firstMatch.exists,
                       "The navigation bar should auto hide again on swipe")
    }
    
    func testScrollToBottomLoadsMoreItems() {
        let app = XCUIApplication()
        let previousCellsCount = app.collectionViews.cells.count
        
        app.collectionViews.cells.otherElements.firstMatch.swipeUp()
        XCTAssertGreaterThan(app.collectionViews.cells.count, previousCellsCount)
    }
    
    func testDeviceRotationRecalculatesCellSizes() {
        let app = XCUIApplication()
        let cellWidthOnPortrait = app.collectionViews.cells.otherElements.firstMatch.frame.size.width
        
        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertGreaterThan(app.collectionViews.cells.otherElements.firstMatch.frame.size.width, cellWidthOnPortrait)
    }
}
