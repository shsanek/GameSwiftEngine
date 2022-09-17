//
//  ContentView.swift
//  GameEngine
//
//  Created by Alex Shipin on 12.09.2022.
//

import SwiftUI
import simd
import GameSwiftEngine

struct ContentView: View {
    let state = GameState()

    var body: some View {
        ZStack {
            SwiftUIView {
                state.view
            }
            VStack {
                Spacer()
                HStack {
                    TrigerView { value in
                        state.controlState.leftTriger = value
                    }
                    Spacer()
                    VStack {
                        Spacer()
                        Button {
                            state.controlState.actionHandler?()
                        } label: {
                            Color(.red)
                        }.frame(height: 50)
                        Spacer()
                    }
                    Spacer()
                    TrigerView { value in
                        state.controlState.rightTriger = value
                    }
                }.frame(height: 120)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
