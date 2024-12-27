import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "User can create a profile",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('trend_sphere', 'create-profile', [
                types.ascii("fashionista"),
                types.ascii("Fashion enthusiast and trend setter")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify profile
        let profileQuery = chain.callReadOnlyFn(
            'trend_sphere',
            'get-profile',
            [types.principal(wallet1.address)],
            wallet1.address
        );
        
        profileQuery.result.expectOk().expectSome();
    }
});

Clarinet.test({
    name: "User can post an outfit",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // First create profile
        let setup = chain.mineBlock([
            Tx.contractCall('trend_sphere', 'create-profile', [
                types.ascii("fashionista"),
                types.ascii("Fashion enthusiast")
            ], wallet1.address)
        ]);
        
        // Post outfit
        let block = chain.mineBlock([
            Tx.contractCall('trend_sphere', 'post-outfit', [
                types.ascii("Summer Vibes"),
                types.ascii("Perfect for beach days"),
                types.ascii("ipfs://QmExample"),
                types.list([types.ascii("summer"), types.ascii("beach")])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify outfit
        let outfitQuery = chain.callReadOnlyFn(
            'trend_sphere',
            'get-outfit',
            [types.uint(1)],
            wallet1.address
        );
        
        outfitQuery.result.expectOk().expectSome();
    }
});

Clarinet.test({
    name: "User can like and favorite outfits",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const creator = accounts.get('wallet_1')!;
        const user = accounts.get('wallet_2')!;
        
        // Setup
        let setup = chain.mineBlock([
            Tx.contractCall('trend_sphere', 'create-profile', [
                types.ascii("creator"),
                types.ascii("Creator profile")
            ], creator.address),
            Tx.contractCall('trend_sphere', 'create-profile', [
                types.ascii("user"),
                types.ascii("User profile")
            ], user.address),
            Tx.contractCall('trend_sphere', 'post-outfit', [
                types.ascii("Test Outfit"),
                types.ascii("Description"),
                types.ascii("ipfs://QmExample"),
                types.list([types.ascii("test")])
            ], creator.address)
        ]);
        
        // Like and favorite
        let block = chain.mineBlock([
            Tx.contractCall('trend_sphere', 'like-outfit', [
                types.uint(1)
            ], user.address),
            Tx.contractCall('trend_sphere', 'favorite-outfit', [
                types.uint(1)
            ], user.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        
        // Verify creator points
        let pointsQuery = chain.callReadOnlyFn(
            'trend_sphere',
            'get-user-points',
            [types.principal(creator.address)],
            creator.address
        );
        
        // 1 point for like + 2 points for favorite = 3 points
        pointsQuery.result.expectOk().expectUint(3);
    }
});