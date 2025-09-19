import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Forest Guardian: Can register a new tree",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('forest-guardian', 'register-tree', [
                types.uint(1),
                types.utf8('Rainforest Central Location'),
                types.utf8('Mahogany'),
                types.uint(100)
            ], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Forest Guardian: Cannot register duplicate tree",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('forest-guardian', 'register-tree', [
                types.uint(1),
                types.utf8('Amazon Basin'),
                types.utf8('Kapok Tree'),
                types.uint(95)
            ], deployer.address),
            Tx.contractCall('forest-guardian', 'register-tree', [
                types.uint(1),
                types.utf8('Different Location'),
                types.utf8('Another Species'),
                types.uint(90)
            ], deployer.address)
        ]);

        block.receipts[1].result.expectErr().expectUint(202);
    }
});

Clarinet.test({
    name: "Forest Guardian: Can report tree tampering",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('forest-guardian', 'register-tree', [
                types.uint(2),
                types.utf8('Wildlife Reserve'),
                types.utf8('Oak'),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('forest-guardian', 'report-tampering', [
                types.uint(2),
                types.uint(75),
                types.utf8('Observed unauthorized logging activity')
            ], deployer.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});