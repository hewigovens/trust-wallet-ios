// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import BigInt
import JSONRPCKit
import APIKit

struct SendViewModel {
    /// stringFormatter of a `SendViewModel` to represent string values with respect of the curent locale.
    lazy var stringFormatter: StringFormatter = {
        return StringFormatter()
    }()
    /// Pair of a `SendViewModel` to represent pair of trade ETH-USD or USD-ETH.
    lazy var currentPair: Pair = {
        return Pair(left: symbol, right: config.currency.rawValue)
    }()
    /// decimals of a `SendViewModel` to represent amount of digits after coma.
    lazy var decimals: Int = {
        switch self.transferType {
        case .ether:
            return config.server.decimals
        case .token(let token):
            return token.decimals
        }
    }()
    /// pairRate of a `SendViewModel` to represent rate of the fiat value to cryptocurrency and vise versa.
    var pairRate: Decimal = 0.0
    /// rate of a `SendViewModel` to represent rate of the fiat value to cryptocurrency and vise versa in string foramt.
    var rate = "0.0"
    /// amount of a `SendViewModel` to represent current amount to send.
    var amount = "0.0"
    /// gasPrice of a `SendViewModel` to represent gas price for send transaction.
    var gasPrice: BigInt?
    /// transferType of a `SendViewModel` to know if it is token or ETH.
    let transferType: TransferType
    /// config of a `SendViewModel` to know configuration of the current account.
    let config: Config
    /// storage of a `SendViewModel` to know pair rate.
    let storage: TokensDataStore
    init(
        transferType: TransferType,
        config: Config,
        storage: TokensDataStore
    ) {
        self.transferType = transferType
        self.config = config
        self.storage = storage
    }
    var title: String {
        return "Send \(symbol)"
    }
    var symbol: String {
        return transferType.symbol(server: config.server)
    }
    var destinationAddress: Address {
        return transferType.contract()
    }
    var backgroundColor: UIColor {
        return .white
    }
    /// Convert `pairRate` to localized human readebale string with respect of the current locale.
    ///
    /// - Returns: `String` that represent `pairRate` in curent locale.
    mutating func pairRateRepresantetion() -> String {
        var formattedString = ""
        if currentPair.left == symbol {
            formattedString = stringFormatter.currency(with: pairRate, and: config.currency.rawValue)
        } else {
            formattedString = stringFormatter.token(with: pairRate, and: decimals)
        }
        rate = formattedString
        return  "~ \(formattedString) " + "\(currentPair.right)"
    }
    /// Amount to send.
    ///
    /// - Returns: `String` that represent amount to send.
    mutating func sendAmount() -> String {
        return amount
    }
    /// Update of the current pair rate.
    ///
    /// - Parameters:
    ///   - price: Decimal cuurent price of the token.
    ///   - amount: Decimal current amount to send.
    mutating func updatePaitRate(with price: Decimal, and amount: Decimal) {
        if currentPair.left == symbol {
            pairRate = amount * price
        } else {
            pairRate = amount / price
        }
    }
    /// Update of the amount to send.
    ///
    /// - Parameters:
    ///   - stringAmount: String fiat string amount.
    mutating func updateAmount(with stringAmount: String) {
        if currentPair.left == symbol {
            amount  = stringAmount.isEmpty ? "0" : stringAmount
        } else {
            //In case of the fiat value we should take pair rate.
            amount  = rate
        }
    }
    /// Update of the pair price with ticker.
    ///
    /// - Parameters:
    ///   - amount: Decimal amount to calculate price.
    mutating func updatePairPrice(with amount: Decimal) {
        guard let rates = storage.tickers, let currentTokenInfo = rates[destinationAddress.description], let price = Decimal(string: currentTokenInfo.price) else {
            return
        }
        updatePaitRate(with: price, and: amount)
    }
    /// If ther is ticker for this pair show fiat view.
    func isFiatViewHidden() -> Bool {
        guard let currentTokenInfo = storage.tickers?[destinationAddress.description], let price = Decimal(string: currentTokenInfo.price), price > 0 else {
            return true
        }
        return false
    }
}
