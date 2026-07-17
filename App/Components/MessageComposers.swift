import SwiftUI
import MessageUI
import UIKit

// MessageComposers — the trusted-contact "share a report" flow. TrustedContact
// is the one saved person (a partner, a doctor's office) reports go to; the two
// composer wrappers hand a filled-out Mail or Messages sheet to the system so
// the actual send stays fully in her control. ComposerAvailability covers the
// simulator/no-account case where neither app can be presented.

struct TrustedContact: Codable, Equatable {
    var name: String
    var relationship: String
    var email: String
    var phone: String

    var hasEmail: Bool { !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var hasPhone: Bool { !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private static let key = "flowtear.trusted"

    static func load() -> TrustedContact? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(TrustedContact.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// Wraps MFMailComposeViewController — the standard "Mail" sheet, pre-filled
// and attached, that the user still has to tap Send on themselves.
struct MailComposer: UIViewControllerRepresentable {
    let to: String
    let subject: String
    let body: String
    let attachments: [(url: URL, mime: String, name: String)]
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(to.isEmpty ? nil : [to])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            if let data = try? Data(contentsOf: attachment.url) {
                vc.addAttachmentData(data, mimeType: attachment.mime, fileName: attachment.name)
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDone: () -> Void
        init(onDone: @escaping () -> Void) { self.onDone = onDone }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                    didFinishWith result: MFMailComposeResult,
                                    error: Error?) {
            controller.dismiss(animated: true, completion: onDone)
        }
    }
}

// Wraps MFMessageComposeViewController — same idea for the "Messages" sheet.
// Attachments only go on if the carrier/device actually supports MMS.
struct MessageComposer: UIViewControllerRepresentable {
    let to: String
    let body: String
    let attachments: [(url: URL, name: String)]
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = to.isEmpty ? nil : [to]
        vc.body = body
        if MFMessageComposeViewController.canSendAttachments() {
            for attachment in attachments {
                _ = vc.addAttachmentURL(attachment.url, withAlternateFilename: attachment.name)
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDone: () -> Void
        init(onDone: @escaping () -> Void) { self.onDone = onDone }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                           didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true, completion: onDone)
        }
    }
}

enum ComposerAvailability {
    static var canMail: Bool { MFMailComposeViewController.canSendMail() }
    static var canText: Bool { MFMessageComposeViewController.canSendText() }

    // mailto: fallback for devices with no Mail account configured (RFC 6068).
    // mailto reserves "&+?=" for its own query syntax on top of the usual
    // query-unsafe set, so those get knocked out of .urlQueryAllowed too.
    static func mailtoFallback(to: String, subject: String, body: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+?=")
        guard let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: allowed),
              let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
    }
}
