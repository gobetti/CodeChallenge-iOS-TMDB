//
//  URLRequestTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 5/01/18.
//

@testable import CodeChallenge
import XCTest

class URLRequestTests: XCTestCase {
    func testParametersAreAddedToURL() {
        let request = URLRequest(url: URL(string: "www.test.com/test")!)
        let parameters = ["param1": "value1", "param2": "value2"]
        let parameterizedRequest = request.addingParameters(parameters)
        XCTAssertEqual(parameterizedRequest.url!.absoluteString, "www.test.com/test?param1=value1&param2=value2")
    }
    
    func testEmptyParametersReturnsSameURL() {
        let request = URLRequest(url: URL(string: "www.test.com/test")!)
        let parameters = [String: String]()
        let parameterizedRequest = request.addingParameters(parameters)
        XCTAssertEqual(parameterizedRequest.url!.absoluteString, request.url!.absoluteString)
    }
    
    func testInvalidParameterKeyIsIgnored() {
        let request = URLRequest(url: URL(string: "www.test.com/test")!)
        let invalidKey = String(bytes: [0xD8, 0x00] as [UInt8], encoding: .utf16BigEndian)!
        let parameters = ["param1": "value1", "\(invalidKey)": "value2"]
        let parameterizedRequest = request.addingParameters(parameters)
        XCTAssertEqual(parameterizedRequest.url!.absoluteString, "www.test.com/test?param1=value1")
    }
    
    func testInvalidParameterValueIsIgnored() {
        let request = URLRequest(url: URL(string: "www.test.com/test")!)
        let invalidValue = String(bytes: [0xD8, 0x00] as [UInt8], encoding: .utf16BigEndian)!
        let parameters = ["param1": "value1", "param2": "\(invalidValue)"]
        let parameterizedRequest = request.addingParameters(parameters)
        XCTAssertEqual(parameterizedRequest.url!.absoluteString, "www.test.com/test?param1=value1")
    }
    
    func testRequestWithoutURLIsNotModified() {
        var request = URLRequest(url: URL(string: "www.test.com/test")!)
        request.url = nil
        let parameters = ["param1": "value1", "param2": "value2"]
        let parameterizedRequest = request.addingParameters(parameters)
        XCTAssertEqual(parameterizedRequest, request)
    }
}
