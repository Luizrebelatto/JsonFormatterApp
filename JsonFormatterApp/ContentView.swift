//
//  ContentView.swift
//  JsonFormatterApp
//
//  Created by Luiz Gabriel Rebelatto Bianchi on 01/11/24.

import SwiftUI

struct JSONNode: Identifiable {
    let id = UUID()
    let key: String?
    let value: Any
    var isExpanded: Bool
    
    var isCollection: Bool {
        value is [String: Any] || value is [Any]
    }
}

struct JSONNodeView: View {
    let node: JSONNode
    let level: Int
    @State private var isExpanded: Bool
    
    init(node: JSONNode, level: Int) {
        self.node = node
        self.level = level
        _isExpanded = State(initialValue: node.isExpanded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if node.isCollection {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 10)
                }
                
                Text(formattedKey)
                    .fontWeight(node.key != nil ? .bold : .regular)
                
                if !node.isCollection {
                    Text(formattedValue)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, CGFloat(level * 20))
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isCollection {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded && node.isCollection {
                ForEach(childNodes) { childNode in
                    JSONNodeView(node: childNode, level: level + 1)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var formattedKey: String {
        if let key = node.key {
            return "\"\(key)\": "
        }
        return ""
    }
    
    private var formattedValue: String {
        if let stringValue = node.value as? String {
            return "\"\(stringValue)\""
        }
        return "\(node.value)"
    }
    
    private var childNodes: [JSONNode] {
        if let dict = node.value as? [String: Any] {
            return dict.map { JSONNode(key: $0.key, value: $0.value, isExpanded: true) }
        } else if let array = node.value as? [Any] {
            return array.enumerated().map { JSONNode(key: "[\($0.offset)]", value: $0.element, isExpanded: true) }
        }
        return []
    }
}

struct ContentView: View {
    @State private var inputJSON: String = ""
    @State private var parsedJSON: Any?
    @State private var errorMessage: String?
    @State private var isCopied: Bool = false
    @State private var selectedFileType: FileType = .json

    let fixedWidth: CGFloat = 250
    
    enum FileType: String, CaseIterable, Identifiable {
        case json = "JSON"
        case xml = "XML"
        case yaml = "YAML"
        case sql = "SQL"
        case html = "HTML"
        
        var id: String { self.rawValue }
    }

    var body: some View {
        VStack {
            Text("\(selectedFileType.rawValue) Formatter")
                .font(.largeTitle)
                .padding()

            Menu {
                ForEach(FileType.allCases) { type in
                    Button(action: {
                        selectedFileType = type
                    }) {
                        Text(type.rawValue)
                    }
                }
            } label: {
                HStack {
                    Text("Select File Type: \(selectedFileType.rawValue)")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            .padding()

            HStack {
                VStack {
                    Text("Input \(selectedFileType.rawValue)")
                        .font(.headline)
                    TextEditor(text: $inputJSON)
                        .border(Color.gray)
                        .frame(width: fixedWidth, height: 200)
                }

                VStack {
                    Text("Formatted \(selectedFileType.rawValue)")
                        .font(.headline)
                    if let json = parsedJSON {
                        ScrollView {
                            if let dict = json as? [String: Any] {
                                JSONNodeView(node: JSONNode(key: nil, value: dict, isExpanded: true), level: 0)
                            } else if let array = json as? [Any] {
                                JSONNodeView(node: JSONNode(key: nil, value: array, isExpanded: true), level: 0)
                            }
                        }
                        .border(Color.gray)
                        .frame(width: fixedWidth, height: 200)
                    } else {
                        TextEditor(text: .constant(""))
                            .border(Color.gray)
                            .frame(width: fixedWidth, height: 200)
                    }
                }
            }
            .padding()

            HStack {
                Button("Format \(selectedFileType.rawValue)") {
                    formatJSON()
                }
                .padding()
                .disabled(inputJSON.isEmpty)

                Button("Clear Fields") {
                    clearFields()
                }
                .padding()

                Button("Copy") {
                    copyResult()
                }
                .padding()
                .disabled(parsedJSON == nil)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
        .padding()
        .frame(width: 600, height: 400)
        .background(Color.white)
    }

    private func formatJSON() {
        do {
            let data = Data(inputJSON.utf8)
            parsedJSON = try JSONSerialization.jsonObject(with: data, options: [])
            errorMessage = nil
        } catch {
            parsedJSON = nil
            errorMessage = "Invalid \(selectedFileType.rawValue)."
        }
    }

    private func clearFields() {
        inputJSON = ""
        parsedJSON = nil
        errorMessage = nil
    }

    private func copyResult() {
        if let json = parsedJSON {
            do {
                let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                if let formattedString = String(data: data, encoding: .utf8) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(formattedString, forType: .string)
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }
            } catch {
                errorMessage = "Error copying \(selectedFileType.rawValue)"
            }
        }
    }
}

#Preview {
    ContentView()
}
