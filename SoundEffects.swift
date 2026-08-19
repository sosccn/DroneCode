import AudioToolbox

enum UISound {
    case blockPickUp
    case blockDrop
    case blockDelete
    case controlTap
    case cameraTap
    case navTap

    private var id: SystemSoundID {
        switch self {
        case .blockPickUp: return 1103
        case .blockDrop:   return 1104
        case .blockDelete: return 1105
        case .controlTap:  return 1057
        case .cameraTap:   return 1052
        case .navTap:      return 1005
        }
    }

    func play() {
        AudioServicesPlaySystemSound(id)
    }
}
