// [Previous test imports and setup remain the same...]

Clarinet.test({
    name: "Test investment with proper fund tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const startup = accounts.get('wallet_1')!;
        const investor = accounts.get('wallet_3')!;
        
        // Setup and registration
        let setupBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'register-startup', [
                types.ascii("Test Startup"),
                types.ascii("A test startup description"),
                types.uint(1000000)
            ], startup.address),
            Tx.contractCall('spark-nest', 'register-investor', [
                types.ascii("Test Investor")
            ], investor.address)
        ]);
        
        setupBlock.receipts.map(receipt => receipt.result.expectOk());
        
        // Make investment
        let investBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'invest', [
                types.principal(startup.address),
                types.uint(100000)
            ], investor.address)
        ]);
        
        investBlock.receipts[0].result.expectOk();
        
        // Verify updated balances
        let startupData = chain.callReadOnlyFn(
            'spark-nest',
            'get-startup',
            [types.principal(startup.address)],
            startup.address
        ).result.expectSome();
        
        let investorData = chain.callReadOnlyFn(
            'spark-nest',
            'get-investor',
            [types.principal(investor.address)],
            investor.address
        ).result.expectSome();
        
        assertEquals(startupData['funds-raised'], types.uint(100000));
        assertEquals(investorData['total-invested'], types.uint(100000));
    }
});
