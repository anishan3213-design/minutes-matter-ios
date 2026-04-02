//
//  ResponderSignupDraft.swift
//  Minutes Matter
//

import Combine
import Foundation

final class ResponderSignupDraft: ObservableObject {
    @Published var orgAccessCode: String = ""
    @Published var orgCodeVerified: Bool = false
    @Published var stationName: String = ""
    @Published var stationAddress: String = ""
    @Published var addressVerified: Bool = false
    @Published var phone: String = ""
}
