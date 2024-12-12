//
//  CacheManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

protocol CacheService {
    func setImageCache(url: NSString, data: Data) throws
    func retrieveImageFromCache(with url: NSString) throws -> Data?
    func clearAllCache()
}

final class CacheManager: CacheService {
    private let cache = NSCache<NSString, NSData>()
    private var totalCountLimit: Int = 0
    private var totalCostLimit: Int = 0
    
    init(
        countLimit: Int = 100,
        totalCostLimit: Int = 50 * 1024 * 1024 //50MB
    ) {
        self.cache.countLimit = countLimit
        self.cache.totalCostLimit = totalCostLimit
    }
    
    func setImageCache(url: NSString, data: Data) throws {
        let costLimit = data.count + totalCostLimit
        let countLimit = totalCountLimit + 1
        
        guard cache.totalCostLimit >= costLimit && cache.countLimit >= countLimit else {
            throw BasicErrorAlert.custom(title: CacheError.limitReached.title, subtitle: CacheError.limitReached.subtitle)
        }
        
        self.cache.setObject(data.asNSData, forKey: url)
        self.totalCostLimit = costLimit
        self.totalCountLimit = countLimit
    }
    
    func retrieveImageFromCache(with url: NSString) throws -> Data? {
        guard let cacheData = cache.object(forKey: url)?.asData else {
            throw BasicErrorAlert.custom(title: CacheError.notFound.title, subtitle: CacheError.notFound.subtitle)
        }
        return cacheData
    }
    
    func clearAllCache() {
        cache.removeAllObjects()
        self.totalCostLimit = 0
        self.totalCountLimit = 0
    }
}

enum CacheError: ErrorAlert {
    case limitReached
    case notFound
    
    var title: String {
        switch self {
        case .limitReached:
            return "Cache Limit Reached"
        case .notFound:
            return "Value Not Found"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .limitReached:
            return "No more data can be stored. Please clean up some older entries."
        case .notFound:
            return "No value found in the cache for the provided key."
        }
    }
}
