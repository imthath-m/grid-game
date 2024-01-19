//
//  GameModel.swift
//  GridGame
//
//  Created by Imthathullah on 19/01/24.
//

import Foundation

class GameModel: ObservableObject {
  let rows: Int
  let columns: Int

  @MainActor @Published var policeLocation: Location = .init(row: .zero, column: .zero)
  @MainActor @Published var ghostLocation: Location = .init(row: .zero, column: .zero)
  @MainActor @Published var canShuffle: Bool = true

  init(rows: Int, columns: Int) {
    self.rows = rows
    self.columns = columns
  }

  func shuffle(withDelay addDelay: Bool = true) async throws {
    guard addDelay else {
      // setting initial location
      let (newPoliceLocation, newGhostLocation) = Self.generateRandomLocations(
        policeLocation: nil,
        ghostLocation: nil,
        rows: rows,
        columns: columns
      )
      await setPoliceLocation(newPoliceLocation)
      await setGhostLocation(newGhostLocation)
      return
    }
    await toggleShuffle()
    let currentPoliceLocation = await policeLocation
    let currentGhostLocation = await ghostLocation
    let (newPoliceLocation, newGhostLocation) = Self.generateRandomLocations(
      policeLocation: currentPoliceLocation,
      ghostLocation: currentGhostLocation,
      rows: rows,
      columns: columns
    )
    try await Task.sleep(for: .seconds(1))
    await setPoliceLocation(newPoliceLocation)
    try await Task.sleep(for: .seconds(1))
    await setGhostLocation(newGhostLocation)
    await toggleShuffle()
  }

  @MainActor private func setPoliceLocation(_ location: Location) {
    policeLocation = location
  }

  @MainActor private func setGhostLocation(_ location: Location) {
    ghostLocation = location
  }

  @MainActor private func toggleShuffle() {
    canShuffle.toggle()
  }

  private static func generateRandomLocations(policeLocation: Location?,
                                              ghostLocation: Location?,
                                              rows: Int,
                                              columns: Int) -> (police: Location,
                                              ghost: Location) {
    guard rows > .zero, columns > .zero else {
      return (police: .zero, ghost: .zero)
    }

    // shuffling police location
    var rowsArray: [Int] = Array<Int>(0..<rows)
    var columnsArray: [Int] = Array(0..<columns)
    if let policeLocation {
      // excluding current police location
      rowsArray.remove(at: policeLocation.row)
      columnsArray.remove(at: policeLocation.column)
    }
    guard let policeRow: Int = rowsArray.randomElement(),
          let policeColumn: Int = columnsArray.randomElement() else {
      return (police: .zero, ghost: .zero)
    }
    let newPoliceLocation: Location = .init(row: policeRow, column: policeColumn)

    // including removed previous police location
    if let policeLocation {
      rowsArray.insert(policeLocation.row, at: policeLocation.row)
      columnsArray.insert(policeLocation.column, at: policeLocation.column)
    }

    // excluding new police location
    rowsArray.remove(at: policeRow)
    columnsArray.remove(at: policeColumn)

    // finding new location of ghost
    if let ghostLocation {
      if ghostLocation.row != policeRow {
        rowsArray.removeAll(where: { $0 == ghostLocation.row })
      }
      if ghostLocation.column != policeColumn {
        columnsArray.removeAll(where: { $0 == ghostLocation.column })
      }
    }
    guard let ghostRow: Int = rowsArray.randomElement(),
            let ghostColumn: Int = columnsArray.randomElement() else {
      return (police: newPoliceLocation, ghost: .zero)
    }
    let newGhostLocation: Location = .init(row: ghostRow, column: ghostColumn)

    return (police: newPoliceLocation, ghost: newGhostLocation)
  }
}

extension GameModel {
  struct Location {
    let row: Int
    let column: Int

    fileprivate static var zero: Location { .init(row: .zero, column: .zero) }
  }
}

extension GameModel.Location: Equatable {
  static func == (lhs: GameModel.Location, rhs: GameModel.Location) -> Bool {
    lhs.row == rhs.row && lhs.column == rhs.column
  }
}
