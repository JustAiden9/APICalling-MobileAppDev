//
//  ContentView.swift
//  API Calling
//
//  Created by Aiden Baker on 3/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var memes = [Item]() // List of memes from the internet
    @State private var showingAlert = false // Show an error message if something goes wrong
    @State private var selectedMeme: Item? // The meme that was tapped
    @State private var showingMemeDetail = false // Show a bigger view of the meme

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16) // Layout: fit as many columns as possible, with spacing
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(memes) { meme in // Go through each meme and show it
                        MemeGridItem(meme: meme)
                            .onTapGesture {
                                selectedMeme = meme // Save the meme that was tapped
                                showingMemeDetail = true // Show more info about that meme
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Epic Memes")
            .task {
                await loadData() // Load memes when the screen appears
            }
            .alert(isPresented: $showingAlert, content: {
                Alert(title: Text("Loading Error"), message: Text("There was a problem loading the Epic Meme data"))
            }) // Show an error popup if loading fails
            .sheet(isPresented: $showingMemeDetail, content: {
                if let meme = selectedMeme {
                    MemeDetailView(meme: meme) // Show details of the meme that was tapped
                }
            })
        }
    }

    // This function gets the memes from a website
    func loadData() async {
        if let url = URL(string: "https://api.imgflip.com/get_memes") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url) // Get the data from the website
                if let decodedResponse = try? JSONDecoder().decode(ApiResponse.self, from: data) {
                    memes = decodedResponse.data.memes // Save the memes to show on screen
                    return
                }
            } catch {
                print("Error fetching data: \(error)") // Print error if it fails
                showingAlert = true // Show the error message
            }
        }
        showingAlert = true // Show error if the URL or decoding fails
    }
}

struct MemeGridItem: View {
    let meme: Item

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: meme.url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
            } placeholder: {
                ProgressView() // Show a loading spinner while image loads
            }
            .frame(height: 100)

            Text(meme.name)
                .font(.caption)
                .lineLimit(2) // Show max 2 lines of text
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MemeDetailView: View {
    let meme: Item

    var body: some View {
        VStack {
            Text(meme.name)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

            AsyncImage(url: URL(string: meme.url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView() // Show spinner while full image loads
            }
            .padding()

            Spacer()
        }
    }
}

#Preview {
    ContentView()
}

// This struct represents one meme
struct Item: Identifiable, Codable {
    var id: String // Meme ID (unique number)
    var name: String // Meme name
    var url: String // Link to the image
    var width: Int
    var height: Int
    var box_count: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case width
        case height
        case box_count
    }
}

// This is used to help read the meme list from the website
struct MemesData: Codable {
    var memes: [Item] // List of memes
}

// This is the full response from the website
struct ApiResponse: Codable {
    var success: Bool // Says if the request worked
    var data: MemesData // The actual list of memes
}
