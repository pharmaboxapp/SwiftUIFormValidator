//
// Created by Shaban on 25/05/2021.
// Copyright (c) 2021 sha. All rights reserved.
//

import Combine
import Foundation

public struct ValidatorContainer {
    let validator: Validatable
    let disableValidation: DisableValidationClosure
}


/// You can use to control the validation form.
/// For example, you can trigger the validation manually. And
/// choose a validation type. And check if the form is valid.
public class FormValidation: ObservableObject {
    /// All the validators added to the form.
    public var validators: [ValidatorContainer] = []

    /// Indicates all form fields valid or not.
    /// You can observe using $allValid
    @Published public var allValid: Bool = false
    @Published public var allFilled: Bool = false

    /// All validation error messages.
    /// You can observe using $validationMessages
    @Published public var validationMessages: [String] = []

    /// Form validation type
    public let validationType: ValidationType

    /// This protocol contains all the messages used by the `FormValidators` provided by the library.
    /// You can override `DefaultValidationMessages` or implement `ValidationMessagesProtocol`.
    public var messages: ValidationMessagesProtocol = DefaultValidationMessages()

    private let onFormChanged: ((FormValidation) -> Void)?

    /// The initialized used to create an instance of this class.
    ///
    /// - Parameters:
    ///   - validationType: ValidationType enum.
    ///   - messages: ValidationMessagesProtocol implementation.
    ///   - onFormChanged: called when any filed changes in the form
    public init(validationType: ValidationType,
                messages: ValidationMessagesProtocol = DefaultValidationMessages(),
                onFormChanged: ((FormValidation) -> Void)? = nil) {
        self.validationType = validationType
        self.messages = messages
        self.onFormChanged = onFormChanged
    }

    /// Used internally for adding a validator
    public func append(_ validator: ValidatorContainer) {
        var val = validator.validator
        val.observeChange(onChanged)
        validators.append(validator)
    }

    /// Called every time a field changes.
    ///
    /// - Parameter validation: Validation
    private func onChanged(validation: Validation) {
        allValid = isAllValid()
        allFilled = isAllFilled()
        validationMessages = allValidationMessages()
        // Its' important to be async to allow the wrapped value of the publisher to be changed.
        DispatchQueue.main.async {
            self.onFormChanged?(self)
        }
    }

    /// Checks if all form fields are filled with text.
    /// This means that there's a text in the field but doesn't mean it's valid.
    /// Note: This function checks only string-based values. For example: it checks if there's string or not in the
    /// value. But other values like Date are not validated.
    ///
    /// - Returns: Bool true if filled.
    public func isAllFilled() -> Bool {
        validators.allSatisfy {
            $0.validator.validate().isSuccess || !$0.validator.isEmpty
        }
    }

    /// Checks if all form fields are valid.
    ///
    /// - Returns: Bool
    public func isAllValid() -> Bool {
        validators.first {
            if $0.disableValidation() {
                return false
            }
            return !$0.validator.validate().isSuccess
        } == nil
    }

    /// Returns a multiline string with all validation errors.
    ///
    /// - Returns: String
    public func allValidationMessagesString() -> String {
        allValidationMessages().joined(separator: "\n")
    }

    /// Returns all validation errors.
    ///
    /// - Returns: String array
    public func allValidationMessages() -> [String] {
        validators.compactMap {
            if $0.disableValidation() {
                return nil
            }
            switch $0.validator.validate() {
            case .success: return nil
            case .failure(let message): return message.isEmpty ? nil : message
            }
        }
    }

    /// Call this function to trigger form validation manually.
    ///
    /// - Returns: Bool indicating the form is valid or not.
    public func triggerValidation() -> Bool {
        validators.forEach {
            $0.validator.triggerValidation(
                    isDisabled: $0.disableValidation(),
                    shouldShowError: validationType.shouldShowError()
            )
        }
        return isAllValid()
    }

    public func errorsDescription() -> String {
        guard !validationMessages.isEmpty else {
            return ""
        }
        return validationMessages.reduce("") { partialResult, s in
            if partialResult.isEmpty {
                return s
            }
            return "\(partialResult)\n\(s)"
        }
    }
}

public extension FormValidation {

    /// Form validation type
    /// It includes 3 cases:
    ///  1) immediate: the validation is triggered every time the field is changed. An error
    ///     message will be shown in case the value is invalid.
    ///  2) deferred: in this case, the validation will be triggered manually only using `FormValidation.triggerValidation()`
    ///     The error messages will be displayed only after triggering the validation manually.
    ///  3) silent: In this case, no validation message is displayed, and it's your responsibility to display them
    ///     using `FormValidation.validationMessages()`.
    enum ValidationType {
        case immediate
        case deferred
        case silent

        func shouldShowError() -> Bool {
            switch self {
            case .immediate,
                 .deferred:
                return true
            case .silent:
                return false
            }
        }
    }


}