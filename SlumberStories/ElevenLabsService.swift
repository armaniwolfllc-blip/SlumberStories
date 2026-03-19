//
//  ElevenLabsService.swift
//  SlumberStories
//
//  Created by Armani Wattie on 3/13/26.
//

import Foundation
import AVFoundation
import Combine

class ElevenLabsService: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var isPlaying = false
    @Published var errorMessage: String?

    #if os(iOS)
    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    #endif

    private let voiceID = "EXAVITQu4vr4xnSDxMaL"

    // Detect if running in simulator
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    func speak(text: String, completion: @escaping () -> Void) {
        if isSimulator {
            speakWithAppleTTS(text: text, completion: completion)
        } else {
            speakWithElevenLabs(text: text, completion: completion)
        }
    }

    // MARK: - Apple TTS (Simulator fallback)
    private func speakWithAppleTTS(text: String, completion: @escaping () -> Void) {
        #if os(iOS)
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false

            let utterance = AVSpeechUtterance(string: text)
            // Use a soft female voice for bedtime feel
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.42        // Slow, calm reading pace
            utterance.pitchMultiplier = 0.95
            utterance.volume = 1.0

            // Find the best available voice
            let voices = AVSpeechSynthesisVoice.speechVoices()
            let preferredVoices = ["Samantha", "Karen", "Moira"]
            for name in preferredVoices {
                if let voice = voices.first(where: { $0.name.contains(name) }) {
                    utterance.voice = voice
                    break
                }
            }

            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            self.synthesizer.delegate = self
            self.synthesizer.speak(utterance)
            self.isPlaying = true
            completion()
        }
        #else
        isPlaying = true
        completion()
        #endif
    }

    // MARK: - ElevenLabs (Real device)
    private func speakWithElevenLabs(text: String, completion: @escaping () -> Void) {
        isLoading = true
        errorMessage = nil

        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_turbo_v2",
            "voice_settings": [
                "stability": 0.75,
                "similarity_boost": 0.85,
                "style": 0.3,
                "use_speaker_boost": true
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = nil
                    self?.isPlaying = true
                    completion()
                    return
                }

                guard let data = data else {
                    self?.isPlaying = true
                    completion()
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let _ = json["detail"] {
                    self?.isPlaying = true
                    completion()
                    return
                }

                #if os(iOS)
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.play()
                    self?.isPlaying = true
                    completion()
                } catch {
                    self?.isPlaying = true
                    completion()
                }
                #else
                self?.isPlaying = true
                completion()
                #endif
            }
        }.resume()
    }

    func pause() {
        #if os(iOS)
        if isSimulator {
            synthesizer.pauseSpeaking(at: .immediate)
        } else {
            audioPlayer?.pause()
        }
        #endif
        isPlaying = false
    }

    func resume() {
        #if os(iOS)
        if isSimulator {
            synthesizer.continueSpeaking()
        } else {
            audioPlayer?.play()
        }
        #endif
        isPlaying = true
    }

    func stop() {
        #if os(iOS)
        if isSimulator {
            synthesizer.stopSpeaking(at: .immediate)
        } else {
            audioPlayer?.stop()
        }
        #endif
        isPlaying = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ElevenLabsService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension ElevenLabsService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
