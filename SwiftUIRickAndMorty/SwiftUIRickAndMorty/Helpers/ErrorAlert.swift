//
//  ErrorAlert.swift
//  SwiftUIRickAndMorty
//
//  Created by Kerem RESNENLİ on 12.12.2024.
//

import Foundation

protocol ErrorAlert: Error, LocalizedError{
    var title: String { get }
    var subtitle: String? { get }
}

enum BasicErrorAlert: ErrorAlert{
    case custom (title: String, subtitle: String?)
    
    var title: String {
        switch self {
        case .custom(let title, _):
            return title
        }
    }
    
    var subtitle: String? {
        switch self {
        case .custom(_, let subtitle):
            return subtitle
        }
    }
}
