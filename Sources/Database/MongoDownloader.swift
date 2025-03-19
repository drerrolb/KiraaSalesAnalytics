//
//  MongoDownloader.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 19/3/2025.
//

import Foundation
import MongoSwiftSync

public struct xxMongoDownloader {
    public static func downloadDocuments() throws -> String {
        // Retrieve the MongoDB URL from the environment variable.
        guard let mongoUrl = ProcessInfo.processInfo.environment["MONGO_URL"] else {
            throw NSError(domain: "EnvironmentVariableError",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "MONGO_URL environment variable is not set."])
        }
        
        // Create a MongoDB client with the URL from the environment variable.
        let client = try MongoClient(mongoUrl)
        
        // Access your database (replace "master" with your actual database name if needed).
        let database = client.db("master")
        
        // Access the desired collection.
        let collection = database.collection("instances")
        
        // Define your BSON query filter.
        let queryFilter: BSONDocument = ["_id": 1]
        
        // Retrieve documents matching the filter.
        let cursor = try collection.find(queryFilter)
        
        // We will collect each document's JSON into an array of Swift objects,
        // then convert that array back into a single JSON string.
        var jsonObjects: [Any] = []
        
        for result in cursor {
            let document = try result.get()
            
            // Convert BSONDocument -> JSON string
            let jsonString = document.toExtendedJSONString()
            
            // Convert the JSON string to a Swift object, then add to the array
            if let jsonData = jsonString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                jsonObjects.append(jsonObject)
            }
        }
        
        // Convert the array of Swift objects into one JSON string.
        let finalData = try JSONSerialization.data(withJSONObject: jsonObjects, options: [])
        let finalJSONString = String(data: finalData, encoding: .utf8) ?? "[]"
        
        return finalJSONString
    }
}
