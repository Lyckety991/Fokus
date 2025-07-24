//
//  SKProductHelper.swift
//  Fokus
//
//  Created by Patrick Lanham on 22.07.25.
//

import Foundation
import StoreKit

// MARK: - SKProductDiscount Extension
extension SKProductDiscount {
    var localizedPriceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
}

// MARK: - SKProduct Extension für bessere Preisformatierung
extension SKProduct {
    var monthlyEquivalentPrice: NSDecimalNumber? {
        guard let subscriptionPeriod = subscriptionPeriod else { return nil }
        
        let monthsInPeriod: NSDecimalNumber
        switch subscriptionPeriod.unit {
        case .day:
            monthsInPeriod = NSDecimalNumber(value: subscriptionPeriod.numberOfUnits).dividing(by: NSDecimalNumber(value: 30))
        case .week:
            monthsInPeriod = NSDecimalNumber(value: subscriptionPeriod.numberOfUnits).dividing(by: NSDecimalNumber(value: 4.33))
        case .month:
            monthsInPeriod = NSDecimalNumber(value: subscriptionPeriod.numberOfUnits)
        case .year:
            monthsInPeriod = NSDecimalNumber(value: subscriptionPeriod.numberOfUnits * 12)
        @unknown default:
            return nil
        }
        
        return price.dividing(by: monthsInPeriod)
    }
    
    var formattedMonthlyEquivalentPrice: String? {
        guard let monthlyPrice = monthlyEquivalentPrice else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: monthlyPrice)
    }
}
