//
//  ContentView.swift
//  JsonFormatterApp
//
//  Created by Luiz Gabriel Rebelatto Bianchi on 01/11/24.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @State private var inputJSON: String = ""
    @State private var formattedJSON: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            Text("JSON Formatter")
                .font(.largeTitle)
                .padding()

            HStack {
                VStack {
                    Text("Input JSON")
                        .font(.headline)
                    TextEditor(text: $inputJSON)
                        .border(Color.gray)
                        .frame(minHeight: 150)
                }

                VStack {
                    Text("Formatted JSON")
                        .font(.headline)
                    TextEditor(text: .constant(formattedJSON))
                        .border(Color.gray)
                        .frame(minHeight: 150)
                        .foregroundColor(errorMessage == nil ? .primary : .red)
                }
            }
            .padding()

            HStack {
                Button("Format JSON") {
                    formatJSON()
                }
                .padding()
                .disabled(inputJSON.isEmpty)

                Button("Clear Fields") {
                    clearFields()
                }
                .padding()

                Button("Copy Result") {
                    copyResult()
                }
                .padding()
                .disabled(formattedJSON.isEmpty)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
        .padding()
        .frame(width: 600, height: 400)
    }

    private func formatJSON() {
        do {
            let data = Data(inputJSON.utf8)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            
            if let formattedString = String(data: formattedData, encoding: .utf8) {
                formattedJSON = formattedString
                errorMessage = nil
            }
        } catch {
            formattedJSON = ""
            errorMessage = "JSON inválido. Verifique a formatação."
        }
    }

    private func clearFields() {
        inputJSON = ""
        formattedJSON = ""
        errorMessage = nil
    }

    private func copyResult() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(formattedJSON, forType: .string)
    }
}

#Preview {
    ContentView()
}
