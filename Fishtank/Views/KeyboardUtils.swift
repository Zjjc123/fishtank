//
//  KeyboardUtils.swift
//  Fishtank
//
//  Created by Jiajun Zhang on 6/19/25.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Keyboard Dismissal Extension
extension View {
  func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

// MARK: - Keyboard Adaptive Modifier
struct KeyboardAdaptive: ViewModifier {
  @State private var keyboardHeight: CGFloat = 0

  func body(content: Content) -> some View {
    GeometryReader { geometry in
      content
        .padding(.bottom, max(0, keyboardHeight - geometry.safeAreaInsets.bottom))
        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
        .onReceive(Publishers.keyboardHeight) { height in
          self.keyboardHeight = height
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}

extension View {
  func keyboardAdaptive() -> some View {
    self.modifier(KeyboardAdaptive())
  }
}

// MARK: - Keyboard Publisher
extension Publishers {
  static var keyboardHeight: AnyPublisher<CGFloat, Never> {
    let willShow = NotificationCenter.default.publisher(
      for: UIResponder.keyboardWillShowNotification
    )
    .map { notification -> CGFloat in
      (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }

    let willHide = NotificationCenter.default.publisher(
      for: UIResponder.keyboardWillHideNotification
    )
    .map { _ -> CGFloat in 0 }

    return MergeMany(willShow, willHide)
      .eraseToAnyPublisher()
  }
} 