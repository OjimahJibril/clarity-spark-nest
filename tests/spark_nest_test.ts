import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test startup registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const startup = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('spark-nest', 'register-startup', [
                types.ascii("Test Startup"),
                types.ascii("A test startup description"),
                types.uint(1000000)
            ], startup.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify startup data
        let getStartupBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'get-startup', [
                types.principal(startup.address)
            ], deployer.address)
        ]);
        
        const startupData = getStartupBlock.receipts[0].result.expectSome();
        assertEquals(startupData.name, "Test Startup");
    }
});

Clarinet.test({
    name: "Test milestone creation and completion",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const startup = accounts.get('wallet_1')!;
        const investor = accounts.get('wallet_3')!;
        
        // Register startup
        let setupBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'register-startup', [
                types.ascii("Test Startup"),
                types.ascii("A test startup description"),
                types.uint(1000000)
            ], startup.address)
        ]);
        
        setupBlock.receipts[0].result.expectOk();
        
        // Add milestone
        let milestoneBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'add-milestone', [
                types.ascii("First milestone"),
                types.uint(100000)
            ], startup.address)
        ]);
        
        milestoneBlock.receipts[0].result.expectOk();
        
        // Complete milestone
        let completeBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'complete-milestone', [
                types.uint(1)
            ], startup.address)
        ]);
        
        completeBlock.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Test mentor registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const mentor = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('spark-nest', 'register-mentor', [
                types.ascii("Test Mentor"),
                types.ascii("Blockchain Development")
            ], mentor.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Test investment and milestone funding process",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const startup = accounts.get('wallet_1')!;
        const investor = accounts.get('wallet_3')!;
        
        // Setup
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
        
        // Add milestone
        let milestoneBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'add-milestone', [
                types.ascii("First milestone"),
                types.uint(100000)
            ], startup.address)
        ]);
        
        milestoneBlock.receipts[0].result.expectOk();
        
        // Make investment
        let investBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'invest', [
                types.principal(startup.address),
                types.uint(100000)
            ], investor.address)
        ]);
        
        investBlock.receipts[0].result.expectOk();
        
        // Complete and approve milestone
        let completeBlock = chain.mineBlock([
            Tx.contractCall('spark-nest', 'complete-milestone', [
                types.uint(1)
            ], startup.address),
            Tx.contractCall('spark-nest', 'approve-milestone', [
                types.principal(startup.address),
                types.uint(1)
            ], investor.address)
        ]);
        
        completeBlock.receipts.map(receipt => receipt.result.expectOk());
    }
});
