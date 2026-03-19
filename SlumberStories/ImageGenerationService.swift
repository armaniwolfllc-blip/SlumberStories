//
//  ImageGenerationService.swift
//  SlumberStories
//

import Foundation
import Combine

class ImageGenerationService: ObservableObject {
    @Published var imageData: Data? = nil
    @Published var isLoading = false

    func generateIllustration(adventure: String, childName: String, adventureKey: String) {
        isLoading = true
        imageData = nil

        let stylePrompt = "Pixar style 3D animated illustration, cinematic lighting, soft warm colors, magical bedtime atmosphere, children's movie quality, highly detailed, dreamy and enchanting"

        let scenePrompt: String
        switch adventureKey {
        case "magical":
            scenePrompt = "A magical glowing kingdom at night with castles, wizards, and sparkling stars, a happy child named \(childName) wearing a magical cloak"
        case "ocean":
            scenePrompt = "An underwater kingdom glowing with bioluminescent light, friendly mermaids and gentle whales, a happy child named \(childName) swimming with sea creatures"
        case "timetravel":
            scenePrompt = "A swirling time portal with dinosaurs and ancient wonders, a happy child named \(childName) exploring through time"
        case "flying":
            scenePrompt = "A child named \(childName) soaring through magical clouds on the back of a friendly dragon, golden sunset sky"
        case "jungle":
            scenePrompt = "A lush magical jungle with ancient temples, colorful exotic animals, a happy child named \(childName) exploring with animal friends"
        case "mountain":
            scenePrompt = "A majestic snowy mountain peak under a starry sky, a happy child named \(childName) at the summit surrounded by snowflakes and aurora lights"
        case "space":
            scenePrompt = "A breathtaking galaxy scene with colorful nebulas and friendly alien worlds, a happy child named \(childName) floating in a spacesuit"
        case "desert":
            scenePrompt = "A warm magical desert at sunset with golden sand dunes, friendly camels and lions, a happy child named \(childName) on safari"
        default:
            scenePrompt = "A magical adventure scene with a happy child named \(childName)"
        }

        let fullPrompt = "\(scenePrompt), \(stylePrompt)"
        let encodedPrompt = fullPrompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=800&height=400&nologo=true&seed=\(Int.random(in: 1...9999))"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data {
                    self.imageData = data
                }
            }
        }.resume()
    }
}
