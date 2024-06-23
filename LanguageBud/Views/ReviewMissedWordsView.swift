//
//  ReviewMissedWordsView.swift
//  LanguageBud
//
//  Created by Benjamin Lutz on 6/22/24.
//

import SwiftUI

struct ReviewMissedWordsView: View {
    @State private var missedWords: [MissedWord] = []
    @State private var errorMessage: String?
    @State private var guesses: [String] = []
    @State private var results: [ReviewResult] = []
    @State private var isReviewResultsViewPresented = false
    let language: String

    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List {
                    ForEach(missedWords.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            AsyncImage(url: URL(string: "http://127.0.0.1:8080/extracted/\(missedWords[index].imagePath)")) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable()
                                         .scaledToFit()
                                         .frame(height: 150)
                                         .cornerRadius(10)
                                case .failure:
                                    Text("Image not available")
                                        .foregroundColor(.gray)
                                        .frame(height: 150)
                                        .cornerRadius(10)
                                @unknown default:
                                    fatalError()
                                }
                            }

                            Text("Word: \(missedWords[index].englishWord)")
                                .font(.headline)
                            TextField("Enter your guess", text: $guesses[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 5)

                            Text("Guesses: \(missedWords[index].correctGuesses)")
                                .font(.subheadline)
                        }
                        .padding()
                    }
                }
                .listStyle(PlainListStyle())

                NavigationLink(destination: ReviewResultsView(results: results), isActive: $isReviewResultsViewPresented) {
                    Button(action: {
                        checkGuesses()
                        isReviewResultsViewPresented = true
                    }) {
                        Text("Check Guesses")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitle("Review Missed Words")
        .onAppear {
            fetchMissedWords()
        }
    }

    private func fetchMissedWords() {
        guard let url = URL(string: "http://127.0.0.1:8080/review_missed_words") else {
            self.errorMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = ["language": language]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch missed words: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }

            do {
                let jsonString = String(data: data, encoding: .utf8)
                print("Received JSON: \(jsonString ?? "No JSON")")
                
                let decodedWords = try JSONDecoder().decode([MissedWord].self, from: data)
                DispatchQueue.main.async {
                    self.missedWords = decodedWords
                    self.guesses = Array(repeating: "", count: decodedWords.count)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode missed words: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func checkGuesses() {
        var resultsArray: [ReviewResult] = []
        for (index, missedWord) in missedWords.enumerated() {
            let guess = guesses[index]
            let resultText = (guess.lowercased() == missedWord.translation.lowercased()) ? "Correct" : "Incorrect - Correct: \(missedWord.translation)"
            let result = ReviewResult(word: missedWord.englishWord, guess: guess, result: resultText)
            resultsArray.append(result)
        }
        self.results = resultsArray
    }
}

struct ReviewMissedWordsView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewMissedWordsView(language: "EN")
    }
}
