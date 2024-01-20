//
//  HomeView.swift
//  GridGame
//
//  Created by Imthathullah on 19/01/24.
//

import SwiftUI

struct HomeView: View {
  @ObservedObject var model: HomeModel = .init()

  var body: some View {
    NavigationStack {
      VStack {
        inputs
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
        // button will be enabled only inputs in the range between 2 and 20.
        // to actually restrict input we can use slider instead of text field
        startButton
      }
    }
  }

  @ViewBuilder var inputs: some View {
    Text("Enter number of rows")
    TextField("Rows", value: $model.rows, formatter: NumberFormatter())
      .padding(.bottom)
    Text("Enter number of columns")
    TextField("Columns", value: $model.columns, formatter: NumberFormatter())
      .padding(.bottom)
  }

  var startButton: some View {
    Button("Start Game") {
      model.setSize()
    }
    .disabled(!model.isValidSize)
    .navigationDestination(item: $model.size) { size in
      GameView(rows: size.rows, columns: size.columns)
    }
  }
}

#Preview {
    HomeView()
}
