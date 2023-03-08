//
// Created by Shaban on 24/05/2021.
// Copyright (c) 2021 sha. All rights reserved.
//

import Foundation
import Combine

public typealias ValidationCallback = (String) -> Bool

/// This validator validates if a condition is valid or not.
public class InlineValidator: StringValidator {
    public var publisher: ValidationPublisher!
    public var subject: ValidationSubject = .init()
    public var onChanged: [OnValidationChange] = []

    private let condition: ValidationCallback

    public init(condition: @escaping ValidationCallback) {
        self.condition = condition
    }

    public var errorMessage: StringProducerClosure = {
        ""
    }
    public var value: String = ""

    public func validate() -> Validation {
        condition(value) ? .success : .failure(message: errorMessage())
    }

    public var isEmpty: Bool {
        value.isEmpty
    }
}
