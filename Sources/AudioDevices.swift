import Foundation
import CoreAudio

class AudioDevices {
    struct AudioDevice {
        let id: AudioDeviceID
        let name: String
        let uid: String
        let isInput: Bool
        let isOutput: Bool
    }
    
    enum AudioDeviceError: Error {
        case deviceNotFound
        case cannotGetProperty
        case cannotSetProperty
        case invalidDevice
    }
    
    // Get all audio devices
    static func getAllDevices() -> [AudioDevice] {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        ) == noErr else {
            return []
        }
        
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        ) == noErr else {
            return []
        }
        
        return deviceIDs.compactMap { deviceID -> AudioDevice? in
            guard let name = getDeviceName(deviceID),
                  let uid = getDeviceUID(deviceID) else {
                return nil
            }
            
            return AudioDevice(
                id: deviceID,
                name: name,
                uid: uid,
                isInput: hasInputStreams(deviceID),
                isOutput: hasOutputStreams(deviceID)
            )
        }
    }
    
    // Get current output device
    static func getCurrentOutputDevice() -> AudioDevice? {
        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        ) == noErr else {
            return nil
        }
        
        guard let name = getDeviceName(deviceID),
              let uid = getDeviceUID(deviceID) else {
            return nil
        }
        
        return AudioDevice(
            id: deviceID,
            name: name,
            uid: uid,
            isInput: hasInputStreams(deviceID),
            isOutput: hasOutputStreams(deviceID)
        )
    }
    
    // Get current input device
    static func getCurrentInputDevice() -> AudioDevice? {
        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        ) == noErr else {
            return nil
        }
        
        guard let name = getDeviceName(deviceID),
              let uid = getDeviceUID(deviceID) else {
            return nil
        }
        
        return AudioDevice(
            id: deviceID,
            name: name,
            uid: uid,
            isInput: hasInputStreams(deviceID),
            isOutput: hasOutputStreams(deviceID)
        )
    }
    
    // Set output device by ID
    static func setOutputDevice(deviceID: AudioDeviceID) throws {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceIDCopy = deviceID
        let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            propertySize,
            &deviceIDCopy
        )
        
        guard status == noErr else {
            throw AudioDeviceError.cannotSetProperty
        }
    }
    
    // Set output device by name
    static func setOutputDevice(name: String) throws {
        let devices = getAllDevices().filter { $0.isOutput }
        
        guard let device = devices.first(where: { $0.name.lowercased().contains(name.lowercased()) }) else {
            throw AudioDeviceError.deviceNotFound
        }
        
        try setOutputDevice(deviceID: device.id)
    }
    
    // Set input device by ID
    static func setInputDevice(deviceID: AudioDeviceID) throws {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceIDCopy = deviceID
        let propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            propertySize,
            &deviceIDCopy
        )
        
        guard status == noErr else {
            throw AudioDeviceError.cannotSetProperty
        }
    }
    
    // Set input device by name
    static func setInputDevice(name: String) throws {
        let devices = getAllDevices().filter { $0.isInput }
        
        guard let device = devices.first(where: { $0.name.lowercased().contains(name.lowercased()) }) else {
            throw AudioDeviceError.deviceNotFound
        }
        
        try setInputDevice(deviceID: device.id)
    }
    
    // Helper: Get device name
    private static func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        ) == noErr else {
            return nil
        }
        
        var name: Unmanaged<CFString>?
        var unmanagedName = name
        propertySize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        
        guard AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &unmanagedName
        ) == noErr, let cfString = unmanagedName?.takeRetainedValue() else {
            return nil
        }
        
        return cfString as String
    }
    
    // Helper: Get device UID
    private static func getDeviceUID(_ deviceID: AudioDeviceID) -> String? {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        guard AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        ) == noErr else {
            return nil
        }
        
        var uid: Unmanaged<CFString>?
        var unmanagedUID = uid
        propertySize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        
        guard AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &unmanagedUID
        ) == noErr, let cfString = unmanagedUID?.takeRetainedValue() else {
            return nil
        }
        
        return cfString as String
    }
    
    // Helper: Check if device has input streams
    private static func hasInputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        return status == noErr && propertySize > 0
    }
    
    // Helper: Check if device has output streams
    private static func hasOutputStreams(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        return status == noErr && propertySize > 0
    }
}
