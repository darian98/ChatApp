import UIKit
import WebRTC
import Firebase

class VideoCallViewController: UIViewController {
    // UI-Elemente
    var localVideoView: RTCMTLVideoView! // Eigenes Video
    var remoteVideoView: RTCMTLVideoView! // Anderer Teilnehmer
    
    let muteButton = UIButton()
    let endCallButton = UIButton()
    
    // WebRTC-Komponenten
    var peerConnection: RTCPeerConnection?
    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var videoCapturer: RTCCameraVideoCapturer?
    
    // Firebase
    var currentUserID: String
    var remoteUserID: String
    var callID: String // Eindeutige Call-ID (z. B. über UUID)

    init(currentUserID: String, remoteUserID: String, callID: String) {
        self.currentUserID = currentUserID
        self.remoteUserID = remoteUserID
        self.callID = callID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startVideoCall()
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        // Lokales Video groß
        localVideoView = RTCMTLVideoView()
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        localVideoView.videoContentMode = .scaleAspectFill
        view.addSubview(localVideoView)
        
        NSLayoutConstraint.activate([
            localVideoView.topAnchor.constraint(equalTo: view.topAnchor),
            localVideoView.leftAnchor.constraint(equalTo: view.leftAnchor),
            localVideoView.rightAnchor.constraint(equalTo: view.rightAnchor),
            localVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Remote Video klein
        remoteVideoView = RTCMTLVideoView()
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        remoteVideoView.videoContentMode = .scaleAspectFill
        view.addSubview(remoteVideoView)
        
        NSLayoutConstraint.activate([
            remoteVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            remoteVideoView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16),
            remoteVideoView.widthAnchor.constraint(equalToConstant: 120),
            remoteVideoView.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        // Mute Button
        muteButton.setTitle("Mute", for: .normal)
        muteButton.backgroundColor = .systemBlue
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        view.addSubview(muteButton)
        
        NSLayoutConstraint.activate([
            muteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            muteButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            muteButton.widthAnchor.constraint(equalToConstant: 100),
            muteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // End Call Button
        endCallButton.setTitle("End Call", for: .normal)
        endCallButton.backgroundColor = .systemRed
        endCallButton.translatesAutoresizingMaskIntoConstraints = false
        endCallButton.addTarget(self, action: #selector(endCall), for: .touchUpInside)
        view.addSubview(endCallButton)
        
        NSLayoutConstraint.activate([
            endCallButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            endCallButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            endCallButton.widthAnchor.constraint(equalToConstant: 100),
            endCallButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func toggleMute() {
        guard let audioTrack = peerConnection?.transceivers.first(where: { $0.mediaType == .audio })?.sender.track else { return }
        audioTrack.isEnabled.toggle()
        muteButton.setTitle(audioTrack.isEnabled ? "Mute" : "Unmute", for: .normal)
    }

    @objc private func endCall() {
        peerConnection?.close()
        dismiss(animated: true)
    }

    private func startVideoCall() {
        // WebRTC-Initialisierung hier
        setupWebRTC()
        createOffer()
        listenForRemoteSDP()
        listenForRemoteICECandidates()
    }
    
    private func listenForIncomingCalls() {
        let db = Firestore.firestore()
        db.collection("calls").whereField("receiverID", isEqualTo: currentUserID)
            .whereField("status", isEqualTo: "incoming")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let data = document.data()
                    let senderID = data["senderID"] as? String ?? ""
                    let callID = document.documentID
                    
                    // Zeige die IncomingCallView an
                   // self.showIncomingCallView(senderID: senderID, callID: callID)
                }
            }
    }

    private func listenForRemoteSDP() {
        let db = Firestore.firestore()
        db.collection("calls").document(callID).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), let type = data["type"] as? String else { return }
             
            // Holen der ReceiverID aus den Daten
            if let receiverID = data["receiverID"] as? String {
                self.remoteUserID = receiverID  // Setzen der Empfänger-ID, falls erforderlich
            }
            
            if type == "offer", let sdp = data["sdp"] as? String {
                // Offer erhalten, nun Antwort erstellen
                self.createAnswer(offerSDP: sdp)
            } else if type == "answer", let sdp = data["sdp"] as? String {
                let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdp)
                self.peerConnection?.setRemoteDescription(remoteDescription, completionHandler: { error in
                    if let error = error {
                        print("Failed to set remote description: \(error.localizedDescription)")
                    } else {
                        print("Remote SDP set successfully")
                    }
                })
            }
        }
    }
    
    private func listenForRemoteICECandidates() {
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
    
    private func createOffer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.offer(for: constraints, completionHandler: { [weak self] offer, error in
            guard let self = self, let offer = offer else { return }
            self.peerConnection?.setLocalDescription(offer, completionHandler: { _ in })
            
            // Sende SDP Offer zu Firebase
            let db = Firestore.firestore()
            let callData: [String: Any] = [
                "type": "offer",
                "sdp": offer.sdp,
                "senderID": self.currentUserID,
                "receiverID": self.remoteUserID,
                "status": "incoming"
            ]
            db.collection("calls").document(self.callID).setData(callData)
        })
    }
    
    private func createAnswer(offerSDP: String) {
        // SDP Antwort erstellen
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.answer(for: constraints, completionHandler: { [weak self] answer, error in
            guard let self = self, let answer = answer else { return }
            self.peerConnection?.setLocalDescription(answer, completionHandler: { _ in })
            
            // Sende SDP Antwort zu Firebase
            let db = Firestore.firestore()
            let callData: [String: Any] = [
                "type": "answer",
                "sdp": answer.sdp,
                "senderID": self.currentUserID,
                "receiverID": self.remoteUserID
            ]
            db.collection("calls").document(self.callID).setData(callData)
        })
    }

    private func setupWebRTC() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let factory = RTCPeerConnectionFactory()
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        // Lokales Video starten
        let videoSource = factory.videoSource()
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        localVideoTrack = factory.videoTrack(with: videoSource, trackId: "localVideoTrack")
        localVideoTrack?.add(localVideoView)
        
        // Hinzufügen zum PeerConnection
        //let stream = factory.mediaStream(withStreamId: "localStream")
        //stream.addVideoTrack(localVideoTrack!)
        //peerConnection?.add(stream)
        peerConnection?.add(localVideoTrack!, streamIds: [])
    }
}

extension VideoCallViewController: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DispatchQueue.main.async {
            if let remoteTrack = stream.videoTracks.first {
                self.remoteVideoTrack = remoteTrack
                self.remoteVideoTrack?.add(self.remoteVideoView)
            }
        }
    }


    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        DispatchQueue.main.async {
            switch newState {
            case .connected:
                print("Connected")
            case .disconnected, .failed, .closed:
                print("Disconnected or failed")
                self.endCall()
            default:
                break
            }
        }
    }


    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateData: [String: Any] = [
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? "",
            "candidate": candidate.sdp
        ]
        let db = Firestore.firestore()
        db.collection("calls").document(self.callID).collection("candidates").addDocument(data: candidateData)
    }


    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
