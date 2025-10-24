import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEnabled = true
    private var musicEnabled = true
    
    enum SoundEffect: String {
        case move = "move"
        case capture = "capture"
        case king = "king"
        case select = "select"
        case invalid = "invalid"
        case gameOver = "gameOver"
        case victory = "victory"
        case defeat = "defeat"
    }
    
    private init() {
        setupAudioSession()
        generateSounds()
        generateBackgroundMusic()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func generateSounds() {
        // Generate procedural sounds using system synthesis
        // These are simple beeps with different frequencies and durations
        
        // Move sound: Mid-frequency click
        createTone(name: "move", frequency: 800, duration: 0.1, volume: 0.3)
        
        // Capture sound: Lower frequency thud
        createTone(name: "capture", frequency: 400, duration: 0.15, volume: 0.4)
        
        // King sound: Ascending tone
        createAscendingTone(name: "king", startFreq: 600, endFreq: 1200, duration: 0.3, volume: 0.3)
        
        // Select sound: High-frequency click
        createTone(name: "select", frequency: 1000, duration: 0.05, volume: 0.2)
        
        // Invalid sound: Descending tone
        createDescendingTone(name: "invalid", startFreq: 600, endFreq: 300, duration: 0.2, volume: 0.25)
        
        // Game over sound: Victory fanfare
        createChord(name: "gameOver", frequencies: [523, 659, 784], duration: 0.5, volume: 0.3)
        
        // Victory sound: Triumphant ascending chord
        createAscendingChord(name: "victory", startFreqs: [400, 500, 600], endFreqs: [800, 1000, 1200], duration: 1.0, volume: 0.35)
        
        // Defeat sound: Sad descending tone
        createDescendingTone(name: "defeat", startFreq: 500, endFreq: 200, duration: 0.8, volume: 0.3)
    }
    
    private func createAscendingChord(name: String, startFreqs: [Float], endFreqs: [Float], duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        var pcmBuffer: AVAudioPCMBuffer?
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(frameCount))
        pcmBuffer?.frameLength = UInt32(frameCount)
        
        let channels = UnsafeBufferPointer(start: pcmBuffer?.floatChannelData, count: 1)
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: frameCount)
        
        for i in 0..<frameCount {
            let progress = Float(i) / Float(frameCount)
            let envelope = sin(progress * .pi)
            var value: Float = 0
            
            for (index, startFreq) in startFreqs.enumerated() {
                let endFreq = endFreqs[index]
                let frequency = startFreq + (endFreq - startFreq) * progress
                value += sin(Float(i) * frequency * 2.0 * .pi / Float(sampleRate))
            }
            
            floats[i] = (value / Float(startFreqs.count)) * envelope * volume
        }
        
        saveBufferToPlayer(buffer: pcmBuffer!, name: name)
    }
    
    private func createTone(name: String, frequency: Float, duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        var pcmBuffer: AVAudioPCMBuffer?
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(frameCount))
        pcmBuffer?.frameLength = UInt32(frameCount)
        
        let channels = UnsafeBufferPointer(start: pcmBuffer?.floatChannelData, count: 1)
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: frameCount)
        
        // Generate sine wave with envelope
        for i in 0..<frameCount {
            let progress = Float(i) / Float(frameCount)
            let envelope = sin(progress * .pi) // Smooth attack and decay
            let value = sin(Float(i) * frequency * 2.0 * .pi / Float(sampleRate)) * envelope * volume
            floats[i] = value
        }
        
        saveBufferToPlayer(buffer: pcmBuffer!, name: name)
    }
    
    private func createAscendingTone(name: String, startFreq: Float, endFreq: Float, duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        var pcmBuffer: AVAudioPCMBuffer?
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(frameCount))
        pcmBuffer?.frameLength = UInt32(frameCount)
        
        let channels = UnsafeBufferPointer(start: pcmBuffer?.floatChannelData, count: 1)
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: frameCount)
        
        for i in 0..<frameCount {
            let progress = Float(i) / Float(frameCount)
            let frequency = startFreq + (endFreq - startFreq) * progress
            let envelope = sin(progress * .pi)
            let value = sin(Float(i) * frequency * 2.0 * .pi / Float(sampleRate)) * envelope * volume
            floats[i] = value
        }
        
        saveBufferToPlayer(buffer: pcmBuffer!, name: name)
    }
    
    private func createDescendingTone(name: String, startFreq: Float, endFreq: Float, duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        var pcmBuffer: AVAudioPCMBuffer?
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(frameCount))
        pcmBuffer?.frameLength = UInt32(frameCount)
        
        let channels = UnsafeBufferPointer(start: pcmBuffer?.floatChannelData, count: 1)
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: frameCount)
        
        for i in 0..<frameCount {
            let progress = Float(i) / Float(frameCount)
            let frequency = startFreq - (startFreq - endFreq) * progress
            let envelope = 1.0 - progress * 0.5
            let value = sin(Float(i) * frequency * 2.0 * .pi / Float(sampleRate)) * envelope * volume
            floats[i] = value
        }
        
        saveBufferToPlayer(buffer: pcmBuffer!, name: name)
    }
    
    private func createChord(name: String, frequencies: [Float], duration: Double, volume: Float) {
        let sampleRate = 44100.0
        let frameCount = Int(sampleRate * duration)
        
        var pcmBuffer: AVAudioPCMBuffer?
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(frameCount))
        pcmBuffer?.frameLength = UInt32(frameCount)
        
        let channels = UnsafeBufferPointer(start: pcmBuffer?.floatChannelData, count: 1)
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: frameCount)
        
        for i in 0..<frameCount {
            let progress = Float(i) / Float(frameCount)
            let envelope = sin(progress * .pi)
            var value: Float = 0
            
            for frequency in frequencies {
                value += sin(Float(i) * frequency * 2.0 * .pi / Float(sampleRate))
            }
            
            floats[i] = (value / Float(frequencies.count)) * envelope * volume
        }
        
        saveBufferToPlayer(buffer: pcmBuffer!, name: name)
    }
    
    private func generateBackgroundMusic() {
        // Generate a soothing ambient background music loop
        // Using a chord progression with soft pads
        let sampleRate = 44100.0
        let duration = 16.0 // 16 second loop
        let frameCount = Int(sampleRate * duration)
        
        var pcmBuffer: AVAudioPCMBuffer?
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: UInt32(frameCount))
        pcmBuffer?.frameLength = UInt32(frameCount)
        
        let channels = UnsafeBufferPointer(start: pcmBuffer?.floatChannelData, count: 1)
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: frameCount)
        
        // Chord progression: C major, A minor, F major, G major
        // Each chord lasts 4 seconds
        let chordProgression: [[Float]] = [
            [261.63, 329.63, 392.00], // C major (C, E, G)
            [220.00, 261.63, 329.63], // A minor (A, C, E)
            [174.61, 220.00, 261.63], // F major (F, A, C)
            [196.00, 246.94, 293.66]  // G major (G, B, D)
        ]
        
        let chordDuration = duration / Double(chordProgression.count)
        let framesPerChord = frameCount / chordProgression.count
        
        for chordIndex in 0..<chordProgression.count {
            let chord = chordProgression[chordIndex]
            let startFrame = chordIndex * framesPerChord
            
            for i in 0..<framesPerChord {
                let globalIndex = startFrame + i
                let progress = Float(i) / Float(framesPerChord)
                
                // Smooth crossfade between chords
                let fadeIn = min(1.0, progress * 4.0)
                let fadeOut = min(1.0, (1.0 - progress) * 4.0)
                let envelope = min(fadeIn, fadeOut)
                
                var value: Float = 0
                
                // Add each note in the chord
                for (noteIndex, frequency) in chord.enumerated() {
                    // Add fundamental frequency
                    value += sin(Float(globalIndex) * frequency * 2.0 * .pi / Float(sampleRate))
                    
                    // Add subtle harmonics for richness
                    value += 0.3 * sin(Float(globalIndex) * frequency * 2.0 * 2.0 * .pi / Float(sampleRate))
                    value += 0.15 * sin(Float(globalIndex) * frequency * 3.0 * 2.0 * .pi / Float(sampleRate))
                    
                    // Add slight detuning for warmth
                    let detuneAmount: Float = 0.5
                    value += 0.2 * sin(Float(globalIndex) * (frequency + detuneAmount) * 2.0 * .pi / Float(sampleRate))
                }
                
                // Normalize and apply envelope with low volume
                floats[globalIndex] = (value / Float(chord.count * 2)) * envelope * 0.08
            }
        }
        
        // Create temporary file for background music
        let tempDir = NSTemporaryDirectory()
        let tempFile = tempDir + "background_music.caf"
        let url = URL(fileURLWithPath: tempFile)
        
        // Save buffer to file
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: pcmBuffer!.format.settings)
            try audioFile.write(from: pcmBuffer!)
            
            // Create player with looping
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop indefinitely
            player.volume = 0.3
            player.prepareToPlay()
            backgroundMusicPlayer = player
        } catch {
            print("Failed to create background music player: \(error)")
        }
    }
    
    private func saveBufferToPlayer(buffer: AVAudioPCMBuffer, name: String) {
        // Create temporary file
        let tempDir = NSTemporaryDirectory()
        let tempFile = tempDir + "\(name).caf"
        let url = URL(fileURLWithPath: tempFile)
        
        // Save buffer to file
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: buffer.format.settings)
            try audioFile.write(from: buffer)
            
            // Create player
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[name] = player
        } catch {
            print("Failed to create audio player for \(name): \(error)")
        }
    }
    
    func play(_ sound: SoundEffect) {
        guard soundEnabled else { return }
        
        if let player = audioPlayers[sound.rawValue] {
            player.currentTime = 0
            player.play()
        }
    }
    
    func playDelayed(_ sound: SoundEffect, delay: TimeInterval) {
        guard soundEnabled else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.play(sound)
        }
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }
    
    func isSoundEnabled() -> Bool {
        return soundEnabled
    }
    
    // Background music controls
    func startBackgroundMusic() {
        guard musicEnabled else { return }
        backgroundMusicPlayer?.play()
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer?.currentTime = 0
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        if enabled {
            startBackgroundMusic()
        } else {
            stopBackgroundMusic()
        }
    }
    
    func isMusicEnabled() -> Bool {
        return musicEnabled
    }
    
    func setMusicVolume(_ volume: Float) {
        backgroundMusicPlayer?.volume = volume
    }
}
