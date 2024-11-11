//
//  ContentView.swift
//  JsonFormatterApp
//
//  Created by Luiz Gabriel Rebelatto Bianchi on 01/11/24.

import SwiftUI
import UniformTypeIdentifiers
import SwiftSoup
import Yams
import AppKit

import Cocoa

struct YAMLFormatter {
    static func format(yaml: String) -> String {
        var formattedLines: [String] = []
        var indentLevel = 0
        
        let lines = yaml.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            guard !trimmedLine.isEmpty else {
                formattedLines.append("")
                continue
            }
            
            if trimmedLine.hasSuffix(":") {
                let indentedLine = String(repeating: "  ", count: indentLevel) + trimmedLine
                formattedLines.append(indentedLine)
                indentLevel += 1
                continue
            }
            
            if trimmedLine.hasPrefix("-") {
                let indentedLine = String(repeating: "  ", count: indentLevel) + trimmedLine
                formattedLines.append(indentedLine)
                continue
            }
            
            let indentedLine = String(repeating: "  ", count: indentLevel) + trimmedLine
            formattedLines.append(indentedLine)
        }
        
        return formattedLines.joined(separator: "\n")
    }
}

struct ContentView: View {
    @State private var inputJSON: String = ""
    @State private var formattedJSON: String = ""
    @State private var errorMessage: String?
    @State private var isCopied: Bool = false
    @State private var selectedFileType: FileType = .json
    
    enum FileType: String, CaseIterable, Identifiable {
        case json = "JSON"
        case xml = "XML"
        case yaml = "YAML"
        case sql = "SQL"
        case html = "HTML"
        
        var id: String { self.rawValue }
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .xml: return "xml"
            case .yaml: return "yaml"
            case .sql: return "sql"
            case .html: return "html"
            }
        }
        
        var utType: UTType {
            switch self {
            case .json: return .json
            case .xml: return .xml
            case .yaml: return UTType("public.yaml") ?? .plainText
            case .sql: return UTType("public.sql") ?? .plainText
            case .html: return .html
            }
        }
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
            
            VStack {
                VStack {
                    Text("Input \(selectedFileType.rawValue)")
                        .font(.headline)
                    TextEditor(text: $inputJSON)
                        .border(Color.gray)
                        .frame(height: 200)
                        
                }
                
                VStack {
                    Text("Formatted \(selectedFileType.rawValue)")
                        .font(.headline)
                    TextEditor(text: .constant(formattedJSON))
                        .border(Color.gray)
                        .frame(height: 200)
                        .disabled(true)
                }
            }
            
            HStack {
                Button("Format \(selectedFileType.rawValue)") {
                    formatJSON()
                }
                .padding()
                .disabled(inputJSON.isEmpty)
                
                Button("Clear") {
                    clearFields()
                }
                .padding()
                
                Button("Copy") {
                    copyResult()
                }
                .padding()
                
                Button("Download") {
                    exportFile()
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
        .frame(width: 500, height: 700)
        .background(Color.primaryBackground)
        .contentMargins(40)
    }
        
    func formatXML(_ xmlString: String) -> String {
        do {
            let xmlData = Data(xmlString.utf8)
            let xmlDocument = try XMLDocument(data: xmlData, options: .nodePrettyPrint)
            
            xmlDocument.characterEncoding = "UTF-8"
            
            return xmlDocument.xmlString(options: .nodePrettyPrint)
        } catch {
            return "Invalid XML format."
        }
    }
    
    func formatHTML(_ htmlString: String) -> String {
        do {
            // Parseia o HTML de entrada
            let document = try SwiftSoup.parse(htmlString)
            
            // Converte o documento de volta para uma string HTML formatada
            let formattedHTML = try document.outerHtml()
            
            return formattedHTML
        } catch {
            // Retorna uma mensagem de erro se o HTML for inválido
            return "Invalid HTML format."
        }
    }
    
    private func formatJSON() {
        switch selectedFileType {
        case .json:
            do {
                let data = Data(inputJSON.utf8)
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                formattedJSON = String(data: prettyData, encoding: .utf8) ?? ""
                errorMessage = nil
            } catch {
                formattedJSON = ""
                errorMessage = "Invalid JSON."
            }
        case .xml:
            formattedJSON = formatXML(inputJSON)
        case .yaml:
            formattedJSON = YAMLFormatter.format(yaml: inputJSON)
        case .html:
            formattedJSON = formatHTML(inputJSON)
        default:
            errorMessage = "Formatting not supported for this type."
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
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
    
    private func exportFile(){
        print("ss")
    }
}

#Preview {
    ContentView()
}
