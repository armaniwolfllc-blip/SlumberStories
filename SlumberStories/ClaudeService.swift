//
//  ClaudeService.swift
//  SlumberStories
//

import Foundation
import Combine

class ClaudeService: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    func generateStory(adventure: String, children: [ChildInfo], petName: String?, completion: @escaping (String) -> Void) {
        isGenerating = true
        errorMessage = nil
        
        let primaryChild = children[0]
        let ageGroup = primaryChild.ageGroup
        
        let ageGuidance: String
        let wordCount: String
        
        switch ageGroup {
        case "2-4":
            ageGuidance = """
            - Use very simple words a toddler understands
            - Short sentences, lots of repetition
            - Magical, whimsical and warm tone
            - Focus on colors, animals, and simple feelings
            - Gentle rhymes where natural
            """
            wordCount = "1000-1200"
        case "5-7":
            ageGuidance = """
            - Use simple but rich language
            - Sentences can be a little longer
            - Include fun descriptive details and a sense of wonder
            - The child hero solves small problems with kindness and courage
            """
            wordCount = "1200-1500"
        case "8-10":
            ageGuidance = """
            - Use more vivid, imaginative language
            - Include a mini quest with a challenge and a resolution
            - The hero shows resilience, creativity and teamwork
            - Weave in themes of growth mindset and abundance naturally
            """
            wordCount = "1400-1700"
        case "11-13":
            ageGuidance = """
            - Use engaging, slightly more mature storytelling
            - Include a meaningful inner journey alongside the outer adventure
            - The hero overcomes self-doubt and discovers their unique strengths
            - Themes of purpose, abundance, and limitless potential
            """
            wordCount = "1600-1900"
        default:
            ageGuidance = "- Use warm, gentle language appropriate for children"
            wordCount = "1200-1500"
        }
        
        let primaryName = primaryChild.name
        var charactersDescription = ""
        
        if children.count == 1 {
            charactersDescription = "The main hero of the story is \(primaryName) (age \(ageGroup))."
        } else {
            let names = children.map { "\($0.name) (age \($0.ageGroup))" }.joined(separator: ", ")
            let allNames = children.map { $0.name }.joined(separator: ", ")
            charactersDescription = """
            The heroes of the story are \(names).
            - \(primaryName) is the main hero and leader of the adventure
            - All children (\(allNames)) go on the adventure together as a team
            - Each child gets meaningful moments to shine and contribute
            - Use each child's name at least 5 times throughout
            """
        }
        
        let petDescription = petName != nil ? """
        - A beloved pet named \(petName!) also joins the adventure
        - \(petName!) plays a fun, helpful role in the story
        - Reference \(petName!) naturally throughout
        """ : ""
        
        let allNames = children.map { $0.name }
        let goodnightNames: String
        if allNames.count == 1 {
            goodnightNames = allNames[0]
        } else if allNames.count == 2 {
            goodnightNames = "\(allNames[0]) and \(allNames[1])"
        } else {
            let last = allNames.last!
            let rest = allNames.dropLast().joined(separator: ", ")
            goodnightNames = "\(rest) and \(last)"
        }
        
        let prompt = """
        Write a beautiful, immersive bedtime story.
        
        Adventure theme: \(adventure)
        
        Characters:
        \(charactersDescription)
        \(petDescription)
        
        Story requirements:
        - \(wordCount) words long (this is important — make it a full, rich story)
        - Start with "Once upon a time"
        - Build a real adventure with a beginning, middle, and end
        - Include vivid scenes, interesting characters, and a satisfying journey
        - Naturally weave in these subconscious positive themes without stating them directly:
            * You are capable of anything you set your mind to
            * Abundance and good things flow to you naturally
            * You are loved, safe, and supported
            * Challenges make you stronger and wiser
            * The world is full of magic and possibility
            * You have everything you need inside you
        - End with a deeply calming, sleepy conclusion as everyone drifts off to sleep
        - The final line should be a warm, personal goodnight to \(goodnightNames)
        
        Age-specific guidance:
        \(ageGuidance)
        
        IMPORTANT FORMATTING RULES:
        - Write only the story, nothing else
        - Do NOT use any markdown formatting whatsoever
        - No hashtags, asterisks, underscores, or special characters
        - No headers or titles
        - No bullet points or numbered lists
        - Just plain flowing prose paragraphs separated by blank lines
        - Make it feel like a classic, timeless bedtime story
        """
        
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 4096,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isGenerating = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(self?.fallbackStory(names: allNames, petName: petName) ?? "")
                    return
                }
                
                guard let data = data else {
                    completion(self?.fallbackStory(names: allNames, petName: petName) ?? "")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = json["content"] as? [[String: Any]],
                       let firstContent = content.first,
                       let text = firstContent["text"] as? String {
                        // Clean any accidental markdown characters
                        let cleanText = text
                            .replacingOccurrences(of: "##", with: "")
                            .replacingOccurrences(of: "# ", with: "")
                            .replacingOccurrences(of: "**", with: "")
                            .replacingOccurrences(of: "__", with: "")
                            .replacingOccurrences(of: "* ", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        completion(cleanText)
                    } else {
                        completion(self?.fallbackStory(names: allNames, petName: petName) ?? "")
                    }
                } catch {
                    self?.errorMessage = error.localizedDescription
                    completion(self?.fallbackStory(names: allNames, petName: petName) ?? "")
                }
            }
        }.resume()
    }
    
    func fallbackStory(names: [String], petName: String?) -> String {
        let primaryName = names[0]
        let petLine = petName != nil ? " Even \(petName!) trotted along, tail wagging with joy." : ""
        let goodnightNames: String
        if names.count == 1 {
            goodnightNames = names[0]
        } else if names.count == 2 {
            goodnightNames = "\(names[0]) and \(names[1])"
        } else {
            let last = names.last!
            let rest = names.dropLast().joined(separator: ", ")
            goodnightNames = "\(rest) and \(last)"
        }
        
        return """
        Once upon a time, \(primaryName) set out on the most incredible adventure the world had ever seen.\(petLine)

        The path ahead glimmered with golden light, and \(primaryName) felt a warm courage rising up from deep inside. Every step forward felt natural, as if the universe itself was guiding them exactly where they needed to go.

        Along the way, they met a wise old owl who perched on a silver branch and said, "You know, the greatest treasure in all the world is not gold or jewels. It lives right inside your heart."

        \(primaryName) smiled, because somehow, they already knew that was true.

        As the stars began to appear one by one in the velvet sky, everyone felt a deep and peaceful calm wash over them. Every challenge on the journey had made them a little wiser. Every moment of courage had made them a little stronger.

        The world was full of magic, and they were full of magic too.

        Now, as the moon rose high and the night wrapped its gentle arms around everything, everyone drifted toward the most wonderful, restful sleep — knowing that tomorrow would bring even more wonder, even more adventure, even more joy.

        Goodnight, \(goodnightNames). You are amazing, you are loved, and the whole world is yours.
        """
    }
}
