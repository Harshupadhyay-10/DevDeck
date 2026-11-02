import Foundation
import Testing
@testable import DevDeckKit

@Test func keychainStoreRoundTripsData() throws {
    let service = "com.byHarshu.DevDeckKitTests.\(UUID().uuidString)"
    let account = "test-account"
    let data = Data("secret".utf8)

    try KeychainStore.save(data, service: service, account: account)
    let loaded = try KeychainStore.load(service: service, account: account)
    #expect(loaded == data)

    try KeychainStore.delete(service: service, account: account)
    let afterDelete = try KeychainStore.load(service: service, account: account)
    #expect(afterDelete == nil)
}

@Test func keychainStoreListsAllAccountsForAService() throws {
    let service = "com.byHarshu.DevDeckKitTests.\(UUID().uuidString)"
    try KeychainStore.save(Data("a".utf8), service: service, account: "account-a")
    try KeychainStore.save(Data("b".utf8), service: service, account: "account-b")

    let accounts = try KeychainStore.allAccounts(service: service)
    #expect(Set(accounts) == ["account-a", "account-b"])

    try KeychainStore.delete(service: service, account: "account-a")
    try KeychainStore.delete(service: service, account: "account-b")
}
