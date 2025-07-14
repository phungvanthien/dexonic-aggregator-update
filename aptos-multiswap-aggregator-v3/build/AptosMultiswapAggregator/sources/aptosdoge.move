module aggregator::aptosdoge {
    use std::string;
    use std::option;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability, Coin};
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use std::signer;
    use aptos_framework::timestamp;

    /// The type identifier of aptosdoge. The account will hold a resource of this type.
    struct AptosDoge has key, store {}

    /// Capabilities for mint, burn, freeze
    struct AptosDogeCapabilities has key {
        burn_cap: BurnCapability<AptosDoge>,
        freeze_cap: FreezeCapability<AptosDoge>,
        mint_cap: MintCapability<AptosDoge>,
    }

    /// Event emitted when aptosdoge is minted
    struct MintEvent has drop, store {
        amount: u64,
        to: address,
    }

    /// Event emitted when aptosdoge is burned
    struct BurnEvent has drop, store {
        amount: u64,
        from: address,
    }

    /// Event handles for aptosdoge
    struct EventStore has key {
        mint_events: EventHandle<MintEvent>,
        burn_events: EventHandle<BurnEvent>,
    }

    /// Initialize the aptosdoge coin
    public entry fun initialize(account: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosDoge>(
            account,
            string::utf8(b"AptosDoge"),
            string::utf8(b"APDOGE"),
            8,
            true
        );

        move_to(account, AptosDoge {});
        move_to(account, AptosDogeCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });

        // Initialize event store
        move_to(account, EventStore {
            mint_events: account::new_event_handle<MintEvent>(account),
            burn_events: account::new_event_handle<BurnEvent>(account),
        });
    }

    /// Mint aptosdoge to the specified account
    public entry fun mint(
        account: &signer,
        to: address,
        amount: u64
    ) acquires AptosDogeCapabilities, EventStore {
        let caps = borrow_global<AptosDogeCapabilities>(@aggregator);
        let coins = coin::mint<AptosDoge>(amount, &caps.mint_cap);
        coin::deposit(to, coins);

        let event_store = borrow_global_mut<EventStore>(@aggregator);
        event::emit_event(&mut event_store.mint_events, MintEvent { amount, to });
    }

    /// Burn aptosdoge from the specified account
    public entry fun burn(
        account: &signer,
        from: address,
        amount: u64
    ) acquires AptosDogeCapabilities, EventStore {
        let caps = borrow_global<AptosDogeCapabilities>(@aggregator);
        let coins = coin::withdraw<AptosDoge>(account, amount);
        coin::burn(coins, &caps.burn_cap);

        let event_store = borrow_global_mut<EventStore>(@aggregator);
        event::emit_event(&mut event_store.burn_events, BurnEvent { amount, from });
    }

    /// Transfer aptosdoge from one account to another
    public entry fun transfer(
        from: &signer,
        to: address,
        amount: u64
    ) {
        coin::transfer<AptosDoge>(from, to, amount);
    }

    /// Get the total supply of aptosdoge
    public fun total_supply(): u64 {
        let supply = coin::supply<AptosDoge>();
        let supply_value = option::extract(&mut supply);
        (supply_value as u64)
    }

    /// Get the balance of aptosdoge for the specified account
    public fun balance_of(account: address): u64 {
        coin::balance<AptosDoge>(account)
    }

    /// Mint aptosdoge for swap operations (called by aggregator)
    public fun mint_for_swap(amount: u64): Coin<AptosDoge> acquires AptosDogeCapabilities {
        let caps = borrow_global<AptosDogeCapabilities>(@aggregator);
        coin::mint<AptosDoge>(amount, &caps.mint_cap)
    }

    /// Burn aptosdoge for swap operations (called by aggregator)
    public fun burn_for_swap(coins: Coin<AptosDoge>) acquires AptosDogeCapabilities {
        let caps = borrow_global<AptosDogeCapabilities>(@aggregator);
        coin::burn(coins, &caps.burn_cap);
    }
} 