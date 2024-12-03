import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol IncomingCallDelegate: AnyObject {
    func didAcceptCall(callID: String, remoteUserID: String)
}

class IncomingCallViewController: UIViewController {
    var senderID: String?
    var callID: String?
    weak var delegate: IncomingCallDelegate?
    
    private let acceptButton = UIButton()
    private let declineButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup der UI-Elemente
        view.backgroundColor = .white
        
        acceptButton.setTitle("Annehmen", for: .normal)
        acceptButton.backgroundColor = .green
        acceptButton.addTarget(self, action: #selector(acceptCall), for: .touchUpInside)
        
        declineButton.setTitle("Ablehnen", for: .normal)
        declineButton.backgroundColor = .red
        declineButton.addTarget(self, action: #selector(declineCall), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [acceptButton, declineButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // Layout-Constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    // Anruf annehmen
    @objc func acceptCall() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        guard let callID = callID, let senderID = senderID else { return }
        print("Accept Call clicked in IncomingViewController")
        // VideoCallService aufrufen, um den Anruf anzunehmen
        VideoCallService.shared.acceptCall(callID: callID, remoteUserID: senderID) { success in
            print("Before Success Bool")
            if success {
                // Wechsel zu Video-Call-UI
                print("Anruf angenommen")
                self.delegate?.didAcceptCall(callID: callID, remoteUserID: senderID)
            } else {
                print("Fehler beim Annehmen des Anrufs")
            }
        }
    }
    
    // Anruf ablehnen
    @objc func declineCall() {
        guard let callID = callID else { return }
        // VideoCallService aufrufen, um den Anruf abzulehnen
        VideoCallService.shared.declineCall(callID: callID)
        
        // Anrufablehnung in Firebase festhalten
        let db = Firestore.firestore()
        db.collection("calls").document(callID).updateData(["status": "declined"]) { error in
            if let error = error {
                print("Fehler beim Ablehnen des Anrufs: \(error.localizedDescription)")
            } else {
                print("Anruf abgelehnt")
            }
        }
    }
}
