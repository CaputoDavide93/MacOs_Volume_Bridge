import Foundation
import AppKit

class MusicControl {
    enum MusicError: Error {
        case scriptExecutionFailed
        case musicNotRunning
        case invalidParameter
    }
    
    // Check if Music app is running
    static func isMusicRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }
    
    // Get current playback state
    static func getPlaybackState() -> String {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    return "playing"
                else if player state is paused then
                    return "paused"
                else
                    return "stopped"
                end if
            end tell
        else
            return "stopped"
        end if
        """
        
        return (try? executeAppleScript(script)) ?? "stopped"
    }
    
    // Play/Pause toggle
    static func playPause() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music" to playpause
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Play
    static func play() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music" to play
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Pause
    static func pause() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music" to pause
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Stop
    static func stop() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music" to stop
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Next track
    static func nextTrack() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music" to next track
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Previous track
    static func previousTrack() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music" to previous track
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Get current track info
    static func getCurrentTrackInfo() -> [String: Any] {
        guard isMusicRunning() else {
            return [
                "is_playing": false,
                "state": "stopped",
                "title": "",
                "artist": "",
                "album": "",
                "duration": 0,
                "position": 0
            ]
        }
        
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is not stopped then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set albumName to album of current track
                    set trackDuration to duration of current track
                    set trackPosition to player position
                    set playerState to player state as string
                    return trackName & "|" & artistName & "|" & albumName & "|" & trackDuration & "|" & trackPosition & "|" & playerState
                else
                    return "|||||stopped"
                end if
            end tell
        else
            return "|||||stopped"
        end if
        """
        
        guard let result = try? executeAppleScript(script) else {
            return ["is_playing": false, "state": "stopped"]
        }
        
        let parts = result.split(separator: "|").map(String.init)
        
        let state = parts.count > 5 ? parts[5].lowercased() : "stopped"
        
        return [
            "is_playing": state == "playing",
            "state": state,
            "title": parts.count > 0 ? parts[0] : "",
            "artist": parts.count > 1 ? parts[1] : "",
            "album": parts.count > 2 ? parts[2] : "",
            "duration": parts.count > 3 ? Int(Double(parts[3]) ?? 0) : 0,
            "position": parts.count > 4 ? Int(Double(parts[4]) ?? 0) : 0
        ]
    }
    
    // Seek to position (in seconds)
    static func seek(to position: Int) throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        guard position >= 0 else {
            throw MusicError.invalidParameter
        }
        
        let script = """
        tell application "Music" to set player position to \(position)
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Toggle shuffle
    static func toggleShuffle() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music"
            set shuffle enabled to not shuffle enabled
            return shuffle enabled
        end tell
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Get shuffle state
    static func getShuffleState() -> Bool {
        guard isMusicRunning() else {
            return false
        }
        
        let script = """
        tell application "Music"
            return shuffle enabled
        end tell
        """
        
        let result = (try? executeAppleScript(script)) ?? "false"
        return result.lowercased() == "true"
    }
    
    // Toggle repeat mode
    static func toggleRepeat() throws {
        guard isMusicRunning() else {
            throw MusicError.musicNotRunning
        }
        
        let script = """
        tell application "Music"
            if song repeat is off then
                set song repeat to all
            else if song repeat is all then
                set song repeat to one
            else
                set song repeat to off
            end if
            return song repeat as string
        end tell
        """
        
        _ = try executeAppleScript(script)
    }
    
    // Get repeat mode
    static func getRepeatMode() -> String {
        guard isMusicRunning() else {
            return "off"
        }
        
        let script = """
        tell application "Music"
            return song repeat as string
        end tell
        """
        
        let result = (try? executeAppleScript(script)) ?? "off"
        return result.lowercased()
    }
    
    // Execute AppleScript
    private static func executeAppleScript(_ script: String) throws -> String {
        var error: NSDictionary?
        
        guard let scriptObject = NSAppleScript(source: script) else {
            throw MusicError.scriptExecutionFailed
        }
        
        let output = scriptObject.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error: \(error)")
            throw MusicError.scriptExecutionFailed
        }
        
        return output.stringValue ?? ""
    }
}
