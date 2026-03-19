//
//  AmbientAudioService.swift
//  SlumberStories
//

import Foundation
import AVFoundation

class AmbientAudioService {

    private var engine: AVAudioEngine?
    private var toneNodes: [AVAudioSourceNode] = []
    private var mixerNode: AVAudioMixerNode?
    private var currentVolume: Float = 0.35

    // Theta binaural beat:
    // Left ear: 200Hz base tone
    // Right ear: 206Hz (200 + 6Hz difference = 6Hz Theta beat perceived by brain)
    private let leftFrequency: Double = 200.0
    private let rightFrequency: Double = 206.0

    private var leftPhase: Double = 0
    private var rightPhase: Double = 0

    func play(adventureKey: String, volume: Float) {
        stop()
        currentVolume = volume

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        let engine = AVAudioEngine()
        let mixer = AVAudioMixerNode()
        engine.attach(mixer)

        let sampleRate = 44100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        var leftPhaseVal = 0.0
        var rightPhaseVal = 0.0
        let lFreq = leftFrequency
        let rFreq = rightFrequency

        let sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftBuffer = ablPointer[0].mData?.assumingMemoryBound(to: Float.self)
            let rightBuffer = ablPointer[1].mData?.assumingMemoryBound(to: Float.self)

            for frame in 0..<Int(frameCount) {
                let leftSample = Float(sin(2.0 * .pi * leftPhaseVal))
                let rightSample = Float(sin(2.0 * .pi * rightPhaseVal))

                leftBuffer?[frame] = leftSample * 0.15
                rightBuffer?[frame] = rightSample * 0.15

                leftPhaseVal += lFreq / sampleRate
                if leftPhaseVal >= 1.0 { leftPhaseVal -= 1.0 }

                rightPhaseVal += rFreq / sampleRate
                if rightPhaseVal >= 1.0 { rightPhaseVal -= 1.0 }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        mixer.outputVolume = volume

        do {
            try engine.start()
            self.engine = engine
            self.mixerNode = mixer
        } catch {
            print("Audio engine error: \(error)")
        }
    }

    func setVolume(_ volume: Float) {
        currentVolume = volume
        mixerNode?.outputVolume = volume
    }

    func pause() {
        engine?.pause()
    }

    func resume() {
        try? engine?.start()
    }

    func stop() {
        engine?.stop()
        engine = nil
        mixerNode = nil
    }
}
