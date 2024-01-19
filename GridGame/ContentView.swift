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
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        Text("Enter number of columns")
          .padding(.top)
        TextField("Columns", value: $model.columns, formatter: NumberFormatter())
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        NavigationLink("Start Game", destination: GameView(rows: model.rows, columns: model.columns))
          .disabled(model.rows == .zero || model.columns == .zero)
          .padding(.top)
      }
    }
  }
}

class HomeModel: ObservableObject {
  @Published var rows: Int = 0
  @Published var columns: Int = 0
}

struct GameView: View {
  @ObservedObject var model: GameModel

  init(rows: Int, columns: Int) {
    self.model = .init(rows: rows, columns: columns)
  }

  var body: some View {
    VStack {
      Text("Police and ghost game")
        .font(.title)
        .padding(.bottom)
      ForEach(0..<model.rows) { row in
        HStack {
          ForEach(0..<model.columns) { column in
            GridItemView(item: gridItem(atRow: row, andColumn: column))
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
  }

  func gridItem(atRow row: Int, andColumn column: Int) -> GridItem {
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

enum GridItem {
  case police
  case ghost
  case empty
}

struct GridItemView: View {
  let item: GridItem

  var body: some View {
    currentItem
      .frame(width: 50, height: 50)
  }

  @ViewBuilder var currentItem: some View {
    switch item {
    case .police:
      ZStack {
        Color.red.opacity(0.3)
        Text("👮‍♂️")
          .font(.title)
      }
    case .ghost:
      ZStack {
        Color.black.opacity(0.3)
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

  @Published var policeLocation: Location
  @Published var ghostLocation: Location
  @Published var canShuffle: Bool = true

  init(rows: Int, columns: Int) {
    self.rows = rows
    self.columns = columns
    (policeLocation, ghostLocation) = Self.generateRandomLocations(rows: rows, columns: columns)
  }

  func shuffle() async throws {
    let (newPoliceLocation, newGhostLocation) = Self.generateRandomLocations(rows: rows, columns: columns)
    try await Task.sleep(for: .seconds(1))
    policeLocation = newPoliceLocation
    try await Task.sleep(for: .seconds(2))
    ghostLocation = newGhostLocation

  }

  static func generateRandomLocations(rows: Int, columns: Int) -> (police: Location, ghost: Location) {
    let policeRow = Int.random(in: 0..<rows)
    let policeColumn = Int.random(in: 0..<columns)
    let ghostRow = Int.random(in: 0..<rows)
    let ghostColumn = Int.random(in: 0..<columns)

    // ensure police, ghost are not in same or column
    guard policeRow != ghostRow && policeColumn != ghostColumn else {
      return generateRandomLocations(rows: rows, columns: columns)
    }
    return (police: .init(row: policeRow, column: policeColumn),
            ghost: .init(row: ghostRow, column: ghostColumn))
  }
}

extension GameModel {
  struct Location {
    let row: Int
    let column: Int
  }
}

#Preview {
  //  ContentView()
  GameView(rows: 5, columns: 5)
}
