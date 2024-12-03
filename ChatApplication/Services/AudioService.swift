import Foundation
import CryptoKit
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

class AudioService: NSObject, AVAudioRecorderDelegate {
    static let shared = AudioService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFilename: URL?
    private var audioPlayer: AVAudioPlayer?
    
    private override init() {}

    // MARK: - Sprachnachricht prüfen
    /// Prüft, ob eine Nachricht eine Sprachnachricht ist, basierend auf der URL und ihrer Dateiendung.
    func isAudioMessage(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let audioExtensions = ["mp3", "m4a", "ogg", "wav", "aac"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }
    
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
        } catch {
            print("Fehler bei der Audio-Sitzung: \(error)")
        }
    }

    // MARK: - Aufnahme starten
    /// Startet die Aufnahme einer Voicemail.
    func startRecording(completion: @escaping (Result<Void, Error>) -> Void) {
        let fileName = UUID().uuidString + ".m4a"
        audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("Aufnahme gestartet...")
            completion(.success(()))
        } catch {
            print("Fehler beim Starten der Aufnahme: \(error)")
            completion(.failure(error))
        }
    }

    // MARK: - Aufnahme stoppen und hochladen
    /// Beendet die Aufnahme und lädt die Sprachnachricht hoch.
//    func stopRecording(chatID: String, senderID: String, receiverID: String, displayName: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        audioRecorder?.stop()
//        audioRecorder = nil
//        print("Aufnahme beendet.")
//        
//        guard let audioURL = audioFilename else {
//            print("Keine Aufnahme gefunden.")
//            completion(.failure(NSError(domain: "AudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Aufnahme verfügbar."])))
//            return
//        }
//        
//        guard FileManager.default.fileExists(atPath: audioURL.path) else {
//            print("Die Datei existiert nicht am angegebenen Speicherort.")
//            return
//        }
//        
//        do {
//            
//            let audioData = try Data(contentsOf: audioURL)
//            print("AudioData Roh: \(audioData)")
//            print("AudioData nach dem recorden hat \(audioData.count)")
//            let base64String = audioData.base64EncodedString(options: .lineLength64Characters)
//            print("Base64 String: \(base64String)")
//            print("Base64-URL: \(base64String)")
//            print("Audio-Daten geladen. Größe: \(audioData.count) Bytes")
//            self.saveAudioMessage(chatID: chatID, base64String: base64String, senderID: senderID, receiverID: receiverID, displayName: displayName) { result in
//                switch result {
//                case .success:
//                    print("Sprachnachricht erfolgreich gespeichert")
//                case .failure(let error):
//                    print("Fehler beim Speichern der Sprachnachricht mit dem Fehler: \(error.localizedDescription)")
//                }
//            }
//        } catch {
//            print("Fehler beim Lesen der Audio-Datei: \(error)")
//            completion(.failure(error))
//        }
//    }
    func stopRecording2(chatID: String, senderID: String, receiverIDs: [String], displayName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        audioRecorder?.stop()
        audioRecorder = nil
        print("Aufnahme beendet.")
        
        guard let audioURL = audioFilename else {
            print("Keine Aufnahme gefunden.")
            completion(.failure(NSError(domain: "AudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Aufnahme verfügbar."])))
            return
        }
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Die Datei existiert nicht am angegebenen Speicherort.")
            return
        }
        
        do {
            
            let audioData = try Data(contentsOf: audioURL)
            print("AudioData nach dem recorden hat \(audioData.count)")
            let base64String = audioData.base64EncodedString(options: .lineLength64Characters)
            let randomID = UUID().uuidString
            print("Base64 String: \(base64String)")
            print("Base64-URL: \(base64String)")
            print("Audio-Daten geladen. Größe: \(audioData.count) Bytes")
            self.saveAudioMessage2(chatID: chatID, messageID: randomID, base64String: base64String, senderID: senderID, receiverIDs: receiverIDs, displayName: displayName) { result in
                switch result {
                case .success:
                    print("Sprachnachricht erfolgreich gespeichert")
                case .failure(let error):
                    print("Fehler beim Speichern der Sprachnachricht mit dem Fehler: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Fehler beim Lesen der Audio-Datei: \(error)")
            completion(.failure(error))
        }
    }
    
    func stopRecording3(chatID: String, senderID: String, receiverIDs: [String], displayName: String, key: SymmetricKey, completion: @escaping (Result<Void, Error>) -> Void) {
        audioRecorder?.stop()
        audioRecorder = nil
        print("Aufnahme beendet.")
        
        guard let audioURL = audioFilename else {
            print("Keine Aufnahme gefunden.")
            completion(.failure(NSError(domain: "AudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Aufnahme verfügbar."])))
            return
        }
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Die Datei existiert nicht am angegebenen Speicherort.")
            return
        }
        
        do {
            
            let audioData = try Data(contentsOf: audioURL)
            print("AudioData nach dem recorden hat \(audioData.count)")
            let base64String = audioData.base64EncodedString(options: .lineLength64Characters)
            let randomID = UUID().uuidString
            print("Base64 String: \(base64String)")
            print("Base64-URL: \(base64String)")
            print("Audio-Daten geladen. Größe: \(audioData.count) Bytes")
            self.saveAudioMessageEncrypted(chatID: chatID, messageID: randomID, base64String: base64String, senderID: senderID, receiverIDs: receiverIDs, displayName: displayName, key: key) { result in
                switch result {
                case .success:
                    print("Sprachnachricht erfolgreich gespeichert")
                case .failure(let error):
                    print("Fehler beim Speichern der Sprachnachricht mit dem Fehler: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Fehler beim Lesen der Audio-Datei: \(error)")
            completion(.failure(error))
        }
    }

//    // MARK: - Sprachnachricht in Firestore speichern
//    private func saveAudioMessage(chatID: String, base64String: String, senderID: String, receiverID: String, displayName: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let data: [String: Any] = [
//            "message": base64String,
//            "receiverID": receiverID,
//            "senderID": senderID,
//            "displayName": displayName,
//            "receiverReadMessage": false,
//            "timestamp": Timestamp(),
//            "isAudio": true
//        ]
//        
//        db.collection("chats").document(chatID).collection("messages").addDocument(data: data) { error in
//            if let error = error {
//                print("Fehler beim Speichern der Sprachnachricht in Firestore: \(error)")
//                completion(.failure(error))
//            } else {
//                print("Sprachnachricht erfolgreich in Firestore gespeichert.")
//                completion(.success(()))
//            }
//        }
//    }
    private func saveAudioMessageEncrypted(chatID: String, messageID: String ,base64String: String, senderID: String, receiverIDs: [String], displayName: String, key: SymmetricKey, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let encryptedMessage = ChatService.shared.encryptMessage(message: base64String, key: key) else {
            print("Fehler: Nachricht konnte nicht verschlüsselt werden.")
            return
        }
        let data: [String: Any] = [
            "message": encryptedMessage.base64EncodedString(),
            "messageID": messageID,
            "receiverIDs": receiverIDs,
            "senderID": senderID,
            "displayName": displayName,
            "receiverReadMessage": false,
            "timestamp": Timestamp(),
            "isAudio": true
        ]
        
        db.collection("chats").document(chatID).collection("messages").addDocument(data: data) { error in
            if let error = error {
                print("Fehler beim Speichern der Sprachnachricht in Firestore: \(error)")
                completion(.failure(error))
            } else {
                print("Sprachnachricht erfolgreich in Firestore gespeichert.")
                // Update last message in chat document
                let lastMessageData: [String: Any] = [
                    "senderID": senderID,
                    "message" : encryptedMessage.base64EncodedString(),
                    "isAudio" : true
                ]
                self.db.collection("chats").document(chatID).updateData([
                    "lastMessage": lastMessageData,
                    "timestamp": Timestamp()
                ]){ error in
                    if let error = error {
                        print("Fehler beim Aktualisieren der lastMessage: \(error.localizedDescription)")
                    } else {
                        print("lastMessage erfolgreich aktualisiert für Chat \(chatID)")
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    private func saveAudioMessage2(chatID: String, messageID: String ,base64String: String, senderID: String, receiverIDs: [String], displayName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "message": base64String,
            "messageID": messageID,
            "receiverIDs": receiverIDs,
            "senderID": senderID,
            "displayName": displayName,
            "receiverReadMessage": false,
            "timestamp": Timestamp(),
            "isAudio": true
        ]
        
        db.collection("chats").document(chatID).collection("messages").addDocument(data: data) { error in
            if let error = error {
                print("Fehler beim Speichern der Sprachnachricht in Firestore: \(error)")
                completion(.failure(error))
            } else {
                print("Sprachnachricht erfolgreich in Firestore gespeichert.")
                completion(.success(()))
            }
        }
    }
    
    // MARK: Audio abspielen
    func playAudio(from base64String: String) {
        print("Base64StringCount: \(base64String.count)")
        guard let audioData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            print("Base64-Decodierung fehlgeschlagen. Prüfe die Eingabedaten.")
            return
        }
        print("Größe der dekodierten Daten: \(audioData.count) Bytes")
        do {
            // Vorherige Wiedergabe stoppen
                   if let player = audioPlayer, player.isPlaying {
                       player.stop()
                       print("Vorherige Wiedergabe gestoppt.")
                       if player.isPlaying {
                           print("Audio wird tatsächlich abgespielt.")
                           print("Länge: \(player.duration)")
                       }
                   }
                   // Neuen Player erstellen
                   audioPlayer = try AVAudioPlayer(data: audioData)
                   audioPlayer?.prepareToPlay()
                   audioPlayer?.play()
            
//            let player = try AVAudioPlayer(data: audioData)
//            player.prepareToPlay()
//            player.play()
        } catch {
            print("Fehler beim Abspielen der Audiodatei: \(error)")
        }
        
        
    }
    
    // MARK: - Hilfsmethode: Speicherort der Dokumente
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
