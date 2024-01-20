//
//  GridGameTests.swift
//  GridGameTests
//
//  Created by Imthathullah on 19/01/24.
//

import XCTest
@testable import GridGame

final class GridGameTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testShuffle() async throws {
    for row in 2..<20 {
      for column in 2..<20 {
        let model = GameModel(rows: row, columns: column)
        print("Starting test on grid of size: \(row)x\(column)")
        let initialPoliceLocation: GameModel.Location = await model.policeLocation
        let initialGhostLocation: GameModel.Location = await model.ghostLocation
        print("initial locations", initialPoliceLocation, initialGhostLocation)
        XCTAssert(initialPoliceLocation.row != initialGhostLocation.row)
        XCTAssert(initialPoliceLocation.column != initialGhostLocation.column)

        try await model.shuffle(withDelay: false)
        let newPoliceLocation: GameModel.Location = await model.policeLocation
        let newGhostLocation: GameModel.Location = await model.ghostLocation
        print("new locations", newPoliceLocation, newGhostLocation)
        XCTAssert(newPoliceLocation != initialPoliceLocation)
        XCTAssert(newGhostLocation != initialGhostLocation)
        XCTAssert(newPoliceLocation.row != newGhostLocation.row)
        XCTAssert(newPoliceLocation.column != newGhostLocation.column)
      }
    }

  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
}

extension GameModel.Location: CustomDebugStringConvertible {
  public var debugDescription: String {
    "(\(row), \(column))"
  }
}
