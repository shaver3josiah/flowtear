import Foundation
import CoreTransferable
import UniformTypeIdentifiers

// FFBackup — one portable file for everything she's made here: cycle history,
// settings, and the whole petal garden. Plain JSON with the two stores' own
// persisted blobs inside, so the same forward-compatible decoding that guards
// UserDefaults guards backups too. No cloud, no account — a file she owns.
struct FFBackupFile: Codable {
    var version = 1
    var exportedAt = Date()
    var cycle: Data      // CycleStore snapshot (logs + settings)
    var rewards: Data    // RewardsStore blob (points + everything owned)
}

enum FFBackup {
    /// Write a backup to a temp file for the share sheet. Nil on any failure.
    static func makeFile(store: CycleStore, rewards: RewardsStore) -> URL? {
        guard let cycle = store.backupData(),
              let garden = rewards.backupData() else { return nil }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(FFBackupFile(cycle: cycle, rewards: garden))
        else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Uncorked-backup-\(df.string(from: Date())).json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// A share item that builds the backup file AT SHARE TIME, so what she
    /// saves is always current — never a snapshot frozen when the button first
    /// rendered (the tuning steppers and Restore live on the same screen).
    struct ShareItem: Transferable {
        let store: CycleStore
        let rewards: RewardsStore

        static var transferRepresentation: some TransferRepresentation {
            FileRepresentation(exportedContentType: .json) { item in
                guard let url = FFBackup.makeFile(store: item.store, rewards: item.rewards)
                else { throw CocoaError(.fileWriteUnknown) }
                return SentTransferredFile(url)
            }
        }
    }

    /// Restore both stores from a backup file's contents — all-or-nothing:
    /// BOTH payloads are validated before EITHER store is touched, so a
    /// corrupt or half-truncated file can never leave the two sides
    /// inconsistent (the destructive confirm dialog promises exactly that).
    @discardableResult
    static func restore(data: Data, store: CycleStore, rewards: RewardsStore) -> Bool {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let file = try? dec.decode(FFBackupFile.self, from: data),
              CycleStore.isValidBackup(file.cycle),
              RewardsStore.isValidBackup(file.rewards)
        else { return false }
        return store.restore(from: file.cycle) && rewards.restore(from: file.rewards)
    }
}
