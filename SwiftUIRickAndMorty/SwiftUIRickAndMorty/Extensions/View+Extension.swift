//
//  View+Extension.swift
//  SwiftUIRickAndMorty
//
//  Created by Kerem RESNENLİ on 12.12.2024.
//

import Foundation
import SwiftUI

extension View {
    func showAlert<T: ErrorAlert, content: View>(alert: Binding<T?>, @ViewBuilder content: @escaping () -> content) -> some View {
        self
            .alert(alert.wrappedValue?.title ?? "Error", isPresented: Binding(value: alert)){
                content()
            } message: {
                if let subtitle = alert.wrappedValue?.subtitle{
                    Text(subtitle)
                }
            }
    }
}
