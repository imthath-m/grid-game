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

  @MainActor @Published var policeLocation: Location
  @MainActor @Published var ghostLocation: Location
  @MainActor @Published var canShuffle: Bool = true

  init(rows: Int, columns: Int) {
    self.rows = rows
    self.columns = columns
    let (newPoliceLocation, newGhostLocation) = Self.generateRandomLocations(
      policeLocation: nil,
      ghostLocation: nil,
      rows: rows,
      columns: columns
    )
    self._policeLocation = .init(initialValue: newPoliceLocation)
    self._ghostLocation = .init(initialValue: newGhostLocation)
  }

  func shuffle(withDelay addDelay: Bool = true) async throws {
    await enableShuffle(false)
    let currentPoliceLocation = await policeLocation
    let currentGhostLocation = await ghostLocation
    let (newPoliceLocation, newGhostLocation) = Self.generateRandomLocations(
      policeLocation: currentPoliceLocation,
      ghostLocation: currentGhostLocation,
      rows: rows,
      columns: columns
    )
    if addDelay {
      try await Task.sleep(for: .seconds(1))
    }
    await setPoliceLocation(newPoliceLocation)
    if addDelay {
      try await Task.sleep(for: .seconds(1))
    }
    await setGhostLocation(newGhostLocation)
    await enableShuffle(true)
  }

  @MainActor private func setPoliceLocation(_ location: Location) {
    policeLocation = location
  }

  @MainActor private func setGhostLocation(_ location: Location) {
    ghostLocation = location
  }

  @MainActor private func enableShuffle(_ flag: Bool) {
    canShuffle = flag
  }

  private static func generateRandomLocations(policeLocation: Location?,
                                              ghostLocation: Location?,
                                              rows: Int,
                                              columns: Int) -> (police: Location,
                                              ghost: Location) {
    guard rows > .zero, columns > .zero else {
      return (police: .zero, ghost: .zero)
    }

    var cells: Set<Int> = Set<Int>(0..<(rows * columns))
    // excluding current police location
    if let policeLocation {
      cells.remove(policeLocation.index)
    }
    
    // shuffling police location
    guard let newPoliceCell: Int = cells.randomElement() else {
      return (police: .zero, ghost: .zero)
    }
    let newPoliceLocation: Location = .init(index: newPoliceCell, columns: columns)

    // including removed previous police location
    if let policeLocation {
      cells.insert(policeLocation.index)
    }

    // excluding new police location's row and column
    cells = cells.filter { $0 / columns != newPoliceLocation.row && $0 % columns != newPoliceLocation.column }

    // excluding old ghost location
    if let ghostLocation {
      cells.remove(ghostLocation.index)
    }
    
    // shuffling ghost location
    guard let newGhostCell: Int = cells.randomElement() else {
      return (police: newPoliceLocation, ghost: .zero)
    }
    let newGhostLocation: Location = .init(index: newGhostCell, columns: columns)

    return (police: newPoliceLocation, ghost: newGhostLocation)
  }
}

extension GameModel {
  struct Location {
    let index: Int
    let columns: Int
    var row: Int { index / columns }
    var column: Int { index % columns }

    fileprivate static var zero: Location { .init(index: .zero, columns: 1) }
  }
}

extension GameModel.Location: Equatable {
  static func == (lhs: GameModel.Location, rhs: GameModel.Location) -> Bool {
    lhs.row == rhs.row && lhs.column == rhs.column
  }
}
