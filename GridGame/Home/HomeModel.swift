//
//  HomeModel.swift
//  GridGame
//
//  Created by Imthathullah on 19/01/24.
//

import Foundation

class HomeModel: ObservableObject {
  struct Size: Hashable {
    let rows: Int
    let columns: Int
  }

  @Published var rows: Int = 5
  @Published var columns: Int = 5

  @MainActor @Published var size: Size? = nil

  @MainActor func setSize() {
    guard isValidSize else { return }
    size = .init(rows: rows, columns: columns)
  }

  var isValidSize: Bool {
    let validRange: ClosedRange<Int> = 2...20
    return validRange.contains(rows) && validRange.contains(columns)
  }
}
