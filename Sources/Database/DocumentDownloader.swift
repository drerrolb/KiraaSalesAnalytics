//
//  DocumentDownloader.swift
//  KiraaSalesAnalytics
//
//  Created by Errol Brandt on 19/3/2025.
//


import Foundation
import MongoSwiftSync

public class DocumentDownloader {
    public init() {}

    /// Downloads documents from MongoDB.
    /// - Returns: An array of BSONDocument.
    /// - Throws: An error if the environment variable is missing or if a MongoDB operation fails.
    public func downloadDocuments() throws -> [BSONDocument] {
        // Retrieve the MongoDB URL from the environment variable.
        guard let mongoUrl = ProcessInfo.processInfo.environment["MONGO_URL"] else {
            throw NSError(
                domain: "EnvironmentVariableError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "MONGO_URL environment variable is not set."]
            )
        }
        
        // Create a MongoDB client with the URL.
        let client = try MongoClient(mongoUrl)
        
        // Access your database (replace "master" with your actual database name if needed).
        let database = client.db("master")
        
        // Access the desired collection.
        let collection = database.collection("instances")
        
        // Define your BSON query filter.
        let queryFilter: BSONDocument = ["_id": 1]
        
        // Retrieve documents matching the filter.
        var retrievedDocuments: [BSONDocument] = []
        let cursor = try collection.find(queryFilter)
        for result in cursor {
            let document = try result.get()
            retrievedDocuments.append(document)
        }
        
        return retrievedDocuments
    }
}