import Foundation
import CoreAudio

class SystemVolume {
    private let defaultOutputDevice: AudioDeviceID
    
    init?() {
        var deviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        
        guard status == noErr else {
            return nil
        }
        
        self.defaultOutputDevice = deviceID
    }
    
    // Get current volume (0.0 - 1.0)
    var volume: Float {
        get {
            var volume = Float(0.0)
            var propertySize = UInt32(MemoryLayout<Float>.size)
            
            var address = AudioObjectPropertyAddress(
                mSelector: AudioObjectPropertySelector(kAudioDevicePropertyVolumeScalar),
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            let status = AudioObjectGetPropertyData(
                defaultOutputDevice,
                &address,
                0,
                nil,
                &propertySize,
                &volume
            )
            
            guard status == noErr else {
                return 0.0
            }
            
            return volume
        }
        set {
            var volume = min(max(newValue, 0.0), 1.0)
            let propertySize = UInt32(MemoryLayout<Float>.size)
            
            var address = AudioObjectPropertyAddress(
                mSelector: AudioObjectPropertySelector(kAudioDevicePropertyVolumeScalar),
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            AudioObjectSetPropertyData(
                defaultOutputDevice,
                &address,
                0,
                nil,
                propertySize,
                &volume
            )
        }
    }
    
    // Get/Set mute status
    var isMuted: Bool {
        get {
            var muted = UInt32(0)
            var propertySize = UInt32(MemoryLayout<UInt32>.size)
            
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            let status = AudioObjectGetPropertyData(
                defaultOutputDevice,
                &address,
                0,
                nil,
                &propertySize,
                &muted
            )
            
            guard status == noErr else {
                return false
            }
            
            return muted == 1
        }
        set {
            var muted = UInt32(newValue ? 1 : 0)
            let propertySize = UInt32(MemoryLayout<UInt32>.size)
            
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            AudioObjectSetPropertyData(
                defaultOutputDevice,
                &address,
                0,
                nil,
                propertySize,
                &muted
            )
        }
    }
    
    // Check if volume control is available
    func hasVolumeControl() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyVolumeScalar),
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        return AudioObjectHasProperty(defaultOutputDevice, &address)
    }
    
    // Check if mute control is available
    func hasMuteControl() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        return AudioObjectHasProperty(defaultOutputDevice, &address)
    }
}
