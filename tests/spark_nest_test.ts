// [Previous test imports and setup remain the same...]

Clarinet.test({
    name: "Test investment with STX transfer and event tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const startup = accounts.get('wallet_1')!;
        const investor = accounts.get('wallet_3')!;
        const initialBalance = investor.balance;
        
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
        const investmentAmount = 100000;
        let investBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'invest', [
                types.principal(startup.address),
                types.uint(investmentAmount)
            ], investor.address)
        ]);
        
        investBlock.receipts[0].result.expectOk();
        
        // Verify STX transfer
        const newBalance = investor.balance;
        assertEquals(newBalance, initialBalance - investmentAmount);
        
        // Verify updated balances and state
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
        
        assertEquals(startupData['funds-raised'], types.uint(investmentAmount));
        assertEquals(investorData['total-invested'], types.uint(investmentAmount));
        
        // Test duplicate investment prevention
        let duplicateInvestBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'invest', [
                types.principal(startup.address),
                types.uint(investmentAmount)
            ], investor.address)
        ]);
        
        duplicateInvestBlock.receipts[0].result.expectErr(107); // err-duplicate-investment
    }
});
