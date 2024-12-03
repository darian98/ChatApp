import Foundation
import WebRTC
import Firebase
import FirebaseAuth

class VideoCallService: NSObject {
    static let shared = VideoCallService()
    
    private var peerConnection: RTCPeerConnection?
    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var callID: String?
    private var currentUserID: String?
    private(set) var isMuted = false
    
    private override init() {
        super.init()
    }
    
    func startCall(currentUserID: String, remoteUserID: String, callID: String, completion: @escaping (Bool) -> Void) {
        self.currentUserID = currentUserID
        self.callID = callID
        
        // WebRTC-Initialisierung und Setup
        setupWebRTC()
        listenForRemoteSDP(callID: callID)
        createOffer(remoteUserID: remoteUserID, callID: callID, completion: completion)
    }
    
    func acceptCall(callID: String, remoteUserID: String, completion: @escaping (Bool) -> Void) {
        self.callID = callID
        updateCallStatus(callID: callID, status: "accepted")
        // WebRTC-Initialisierung und Setup
        setupWebRTC()
        listenForRemoteSDP(callID: callID)
        listenForRemoteICECandidates(callID: callID)
        
        createAnswer(remoteUserID: remoteUserID, callID: callID, completion: completion)
    }
    
    func declineCall(callID: String) {
        updateCallStatus(callID: callID, status: "rejected")
        peerConnection?.close()
        cleanup()
    }
    
    func endCall() {
        if let callID = callID {
            updateCallStatus(callID: callID, status: "ended")
        }
        peerConnection?.close()
        cleanup()
    }
    func toggleMute() {
            guard let audioTrack = peerConnection?.transceivers.first(where: { $0.mediaType == .audio })?.sender.track else { return }
            audioTrack.isEnabled.toggle()
            isMuted = !audioTrack.isEnabled
        }
    
    func updateCallStatus(callID: String, status: String) {
        let db = Firestore.firestore()
        db.collection("calls").document(callID).updateData([
            "status": status
        ]) { error in
            if let error = error {
                print("Fehler beim Aktualisieren des Anrufstatus: \(error.localizedDescription)")
            } else {
                print("Anrufstatus auf \(status) aktualisiert.")
            }
        }
    }

    
    private func setupWebRTC() {
        // WebRTC Setup
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let factory = RTCPeerConnectionFactory()
        
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        // Lokales Video starten
        let videoSource = factory.videoSource()
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        localVideoTrack = factory.videoTrack(with: videoSource, trackId: "localVideoTrack")
    }
    private func listenForRemoteSDP(callID: String) {
        let db = Firestore.firestore()
        db.collection("calls").document(callID).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), let type = data["type"] as? String else { return }
            
            if let sdp = data["sdp"] as? String {
                let sessionDescription = RTCSessionDescription(type: type == "offer" ? .offer : .answer, sdp: sdp)
                
                // Setzen der Remote Description
                self.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { error in
                    if let error = error {
                        print("Fehler beim Setzen der Remote Description: \(error.localizedDescription)")
                    } else {
                        print("Remote Description erfolgreich gesetzt!")
                        
                        if type == "offer" {
                            // Anrufer empfängt eine Offer und muss darauf mit einer Answer antworten
                            self.createAnswer(remoteUserID: data["senderID"] as? String ?? "", callID: callID, completion: { success in
                                // Weiterlogik nach Beantwortung des Angebots
                            })
                        } else if type == "answer" {
                            // Empfänger wartet auf die Answer des Anrufers
                            print("Answer empfangen, Verbindung wird abgeschlossen!")
                        }
                    }
                })
            }
        }
    }

    
    private func listenForRemoteICECandidates(callID: String) {
        let db = Firestore.firestore()
        db.collection("calls").document(callID).collection("candidates").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            snapshot?.documentChanges.forEach { change in
                if change.type == .added {
                    let data = change.document.data()
                    if let sdp = data["candidate"] as? String,
                       let sdpMLineIndex = data["sdpMLineIndex"] as? Int32,
                       let sdpMid = data["sdpMid"] as? String {
                        let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                        self.peerConnection?.add(candidate)
                    }
                }
            }
        }
    }
    
    private func createOffer(remoteUserID: String, callID: String, completion: @escaping (Bool) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.offer(for: constraints, completionHandler: { [weak self] offer, error in
            guard let self = self, let offer = offer else { return }
            
            self.peerConnection?.setLocalDescription(offer, completionHandler: { _ in })
            
            // Sende SDP Offer zu Firebase
            let db = Firestore.firestore()
            let callData: [String: Any] = [
                "type": "offer",
                "sdp": offer.sdp,
                "senderID": self.currentUserID ?? "",
                "receiverID": remoteUserID,
                "status": "incoming"
            ]
            db.collection("calls").document(callID).setData(callData) { error in
                if let error = error {
                    print("Error sending offer: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Offer sent")
                    completion(true)
                }
            }
        })
    }
    
    private func createAnswer(remoteUserID: String, callID: String, completion: @escaping (Bool) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.answer(for: constraints, completionHandler: { [weak self] answer, error in
            guard let self = self, let answer = answer else { return }
            
            self.peerConnection?.setLocalDescription(answer, completionHandler: { _ in })
            
            // Sende SDP Antwort zu Firebase
            let db = Firestore.firestore()
            let callData: [String: Any] = [
                "type": "answer",
                "sdp": answer.sdp,
                "senderID": self.currentUserID ?? "",
                "receiverID": remoteUserID
            ]
            db.collection("calls").document(callID).setData(callData) { error in
                if let error = error {
                    print("Error sending answer: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Answer sent")
                    completion(true)
                }
            }
        })
    }
    func listenForIncomingCalls(completion: @escaping (String, String) -> Void) {
            let currentUserID = Auth.auth().currentUser?.uid ?? ""
            let db = Firestore.firestore()
            db.collection("calls").whereField("receiverID", isEqualTo: currentUserID)
                .whereField("status", isEqualTo: "incoming")
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    
                    for document in documents {
                        let data = document.data()
                        let senderID = data["senderID"] as? String ?? ""
                        let callID = document.documentID
                        completion(senderID, callID)
                    }
                }
        }
    
    private func cleanup() {
        // Cleanup code
        peerConnection = nil
        localVideoTrack = nil
        remoteVideoTrack = nil
        videoCapturer = nil
        callID = nil
        currentUserID = nil
    }
}

extension VideoCallService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
    
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        switch stateChanged {
        case .stable:
            print("Signaling ist stabil.")
        case .haveLocalOffer:
            print("Lokales Angebot wurde erstellt.")
        case .haveRemoteOffer:
            print("Remote-Angebot erhalten.")
        case .haveLocalPrAnswer, .haveRemotePrAnswer:
            print("Vorläufige Antwort erstellt oder empfangen.")
        case .closed:
            print("Verbindung geschlossen.")
        @unknown default:
            print("Unbekannter Signalisierungsstatus.")
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected:
            print("Verbindung erfolgreich hergestellt.")
        case .disconnected:
            print("Verbindung unterbrochen.")
        case .failed:
            print("Verbindung fehlgeschlagen.")
        default:
            break
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
