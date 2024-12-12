//
//  Binding+Extension.swift
//  SwiftUIRickAndMorty
//
//  Created by Kerem RESNENLİ on 12.12.2024.
//

import Foundation
import SwiftUI

extension Binding where Value == Bool {
    
    init<T>(value: Binding<T?>) {
        self.init{
            value.wrappedValue != nil
        } set: { newValue in
            if !newValue {
                value.wrappedValue = nil
            }
        }
    }
}
