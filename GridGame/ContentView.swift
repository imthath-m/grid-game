//
//  ContentView.swift
//  GridGame
//
//  Created by Imthathullah on 19/01/24.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var model: HomeModel = .init()

  var body: some View {
    NavigationStack {
      VStack {
        Text("Enter number of rows")
        // we're assuming inputs will be in the range between 2 and 20.
        // to actually restrict we can use slider instead of text field
        TextField("Rows", value: $model.rows, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        Text("Enter number of columns")
          .padding(.top)
        TextField("Columns", value: $model.columns, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        NavigationLink("Start Game", destination: destination)
          .disabled(model.rows == .zero || model.columns == .zero)
          .padding(.top)
      }
    }
  }

  @ViewBuilder var destination: some View {
    if model.rows == .zero || model.columns == .zero {
      Text("Invalid input")
    } else {
      GameView(rows: model.rows, columns: model.columns)
    }
  }
}

class HomeModel: ObservableObject {
  @Published var rows: Int = 7
  @Published var columns: Int = 9
}

struct GameView: View {
  @ObservedObject var model: GameModel

  init(rows: Int, columns: Int) {
    self.model = .init(rows: rows, columns: columns)
  }

  private var gridLayout: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: model.columns)
  }

  var body: some View {
    VStack {
      Text("Police and ghost game")
        .font(.title)
        .padding(.bottom)

      ScrollView {
        ScrollView(.horizontal) {
          LazyVGrid(columns: gridLayout, spacing: 8) {
            ForEach(0..<(model.rows * model.columns), id: \.self) { index in
              let row = index / model.columns
              let column = index % model.columns
              GridItemView(item: gridItem(atRow: row, andColumn: column))
            }
          }
        }
      }

      Button(action: {
        Task {
          try await model.shuffle()
          // can add some loader while shuffling
        }
      }, label: {
        Text("Shuffle")
      }).disabled(!model.canShuffle)
        .padding(.top)
    }
    .onAppear {
      Task {
        try await model.shuffle(withDelay: false)
      }
    }
  }

  func gridItem(atRow row: Int, andColumn column: Int) -> Item {
    if row == model.policeLocation.row,
       column == model.policeLocation.column {
      return .police
    }
    if row == model.ghostLocation.row,
       column == model.ghostLocation.column {
      return .ghost
    }
    return .empty
  }
}

enum Item {
  case police
  case ghost
  case empty
}

struct GridItemView: View {
  let item: Item

  var body: some View {
    currentItem
      .frame(width: 40, height: 40)
  }

  @ViewBuilder var currentItem: some View {
    switch item {
    case .police:
      ZStack {
        Color.orange.opacity(0.3)
        Text("👮‍♂️")
          .font(.title)
      }
    case .ghost:
      ZStack {
        Color.red.opacity(0.3)
        Text("👻")
          .font(.title)
      }
    case .empty:
      Rectangle()
        .foregroundColor(.green.opacity(0.5))
    }
  }
}


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

  }

  @MainActor func setPoliceLocation(_ location: Location) {
    policeLocation = location
  }

  @MainActor func setGhostLocation(_ location: Location) {
    ghostLocation = location
  }

  static func generateRandomLocations(policeLocation: Location?, ghostLocation: Location?, rows: Int, columns: Int) -> (police: Location, ghost: Location) {
    guard rows > .zero, columns > .zero else {
      return (police: .zero, ghost: .zero)
    }

    var rowsArray: [Int] = Array<Int>(0..<rows)
    var columnsArray: [Int] = Array(0..<columns)
    if let policeLocation {
      rowsArray.remove(at: policeLocation.row)
      columnsArray.remove(at: policeLocation.column)
    }
    guard let policeRow: Int = rowsArray.randomElement(), let policeColumn: Int = columnsArray.randomElement() else {
      return (police: .zero, ghost: .zero)
    }
    let newPoliceLocation: Location = .init(row: policeRow, column: policeColumn)

    if let policeLocation {
      rowsArray.insert(policeLocation.row, at: policeLocation.row)
      columnsArray.insert(policeLocation.column, at: policeLocation.column)
    }

    rowsArray.remove(at: policeRow)
    columnsArray.remove(at: policeColumn)
    if let ghostLocation {
      if ghostLocation.row != policeRow {
        rowsArray.removeAll(where: { $0 == ghostLocation.row })
      }
      if ghostLocation.column != policeColumn {
        columnsArray.removeAll(where: { $0 == ghostLocation.column })
      }
    }
    guard let ghostRow: Int = rowsArray.randomElement(), let ghostColumn: Int = columnsArray.randomElement() else {
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

    static var zero: Location { .init(row: .zero, column: .zero) }
  }
}

extension GameModel.Location: Equatable {
  static func == (lhs: GameModel.Location, rhs: GameModel.Location) -> Bool {
    lhs.row == rhs.row && lhs.column == rhs.column
  }
}

#Preview {
  //  ContentView()
  GameView(rows: 5, columns: 5)
}
