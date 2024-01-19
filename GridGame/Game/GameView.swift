//
//  GameView.swift
//  GridGame
//
//  Created by Imthathullah on 19/01/24.
//

import SwiftUI

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

      ScrollView {
        ScrollView(.horizontal) {
          gridView
        }
      }

      shuffleButton
        .padding(.top)
    }
    .onAppear {
      Task {
        try await model.shuffle(withDelay: false)
      }
    }
  }

  private var gridView: some View {
    LazyVGrid(columns: gridLayout, spacing: 8) {
      ForEach(0..<(model.rows * model.columns), id: \.self) { index in
        let row = index / model.columns
        let column = index % model.columns
        GridItemView(item: gridItem(atRow: row, andColumn: column))
      }
    }
  }

  private var shuffleButton: some View {
    Button(action: {
      Task {
        // can add some loader while shuffling
        try await model.shuffle()
      }
    }, label: {
      Text("Shuffle")
    })
    .disabled(!model.canShuffle)
  }

  private var gridLayout: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: model.columns)
  }

  private func gridItem(atRow row: Int, andColumn column: Int) -> Item {
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

private enum Item {
  case police
  case ghost
  case empty
}

private struct GridItemView: View {
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

#Preview {
  GameView(rows: 5, columns: 5)
}
