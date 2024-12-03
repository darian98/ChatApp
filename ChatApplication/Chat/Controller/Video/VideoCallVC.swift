import UIKit
import WebRTC

class VideoCallVC: UIViewController {
    // UI-Elemente
    var localVideoView: RTCMTLVideoView! // Eigenes Video
    var remoteVideoView: RTCMTLVideoView! // Anderer Teilnehmer
    
    let muteButton = UIButton()
    let endCallButton = UIButton()
    
    // Verweise auf den Service
    let videoCallService = VideoCallService.shared
    let currentUserID: String
    let remoteUserID: String
    let callID: String
    
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
        setupVideoStreams()
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
    
    private func setupVideoStreams() {
        // Lokales Video anzeigen
        if let localVideoTrack = videoCallService.localVideoTrack {
            localVideoTrack.add(localVideoView)
        }
        
        // Remote Video anzeigen
        if let remoteVideoTrack = videoCallService.remoteVideoTrack {
            remoteVideoTrack.add(remoteVideoView)
        }
    }

    @objc private func toggleMute() {
        videoCallService.toggleMute()
        let buttonTitle = videoCallService.isMuted ? "Unmute" : "Mute"
        muteButton.setTitle(buttonTitle, for: .normal)
    }

    @objc private func endCall() {
        videoCallService.endCall()
        dismiss(animated: true)
    }
}
