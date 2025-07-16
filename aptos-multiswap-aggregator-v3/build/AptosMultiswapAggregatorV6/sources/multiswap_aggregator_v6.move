module 0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9::multiswap_aggregator_v6 {
    use std::signer;
    use std::vector;
    use std::option::{Self, Option};
    use std::bcs;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;
    use aptos_std::table::{Self, Table};
    use aptos_std::type_info;
    use aptos_framework::aptos_coin::AptosCoin;
    // Import PancakeSwap module
    // XÓA: use 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::swap;

    // DEX integration placeholders (will be replaced with actual imports)
    // Liquidswap address: 0x190d44266241744264b964a37b8f09863167a12d3e70cda39376cfb4e3561e12
    // Econia address: 0xc0deb00c405f84c85dc13442e305df75d9b58c5481e6824349a528b0b78d4bb5
    


    // Mock token structs for testing
    struct USDC has key {}
    struct USDT has key {}

    // Mock WBTC struct nếu không import được module thật
    struct WBTC has store, key {}

    // Error codes
    const E_NOT_ADMIN: u64 = 1;
    const E_INSUFFICIENT_AMOUNT: u64 = 2;
    const E_SLIPPAGE_EXCEEDED: u64 = 3;
    const E_INVALID_DEX: u64 = 4;
    const E_SWAP_FAILED: u64 = 5;
    const E_POOL_NOT_FOUND: u64 = 6;
    const E_DEADLINE_EXCEEDED: u64 = 7;
    const E_INVALID_ROUTE: u64 = 8;
    const E_QUOTE_EXPIRED: u64 = 9;
    const E_INSUFFICIENT_LIQUIDITY: u64 = 10;
    const E_MAX_HOPS_EXCEEDED: u64 = 11;

    // DEX identifiers
    const DEX_LIQUIDSWAP: u8 = 1;
    const DEX_ECONIA: u8 = 2;
    const DEX_PANORA: u8 = 3;
    const DEX_AMNIS: u8 = 4;
    const DEX_ANIMESWAP: u8 = 5;
    const DEX_SUSHISWAP: u8 = 6;
    // 1. Thêm DEX ID cho PancakeSwap
    // XÓA: const DEX_PANCAKESWAP: u8 = 7;

    // Configuration constants
    const MAX_HOPS: u64 = 3;
    const QUOTE_EXPIRY_TIME: u64 = 300; // 5 minutes
    const MIN_LIQUIDITY_THRESHOLD: u64 = 1000; // Minimum liquidity in USD

    // Structs
    struct SwapQuote has copy, drop, store {
        dex_id: u8,
        input_amount: u64,
        output_amount: u64,
        price_impact: u64, // in basis points (1/10000)
        fee: u64, // in basis points
        route: vector<address>, // token addresses in swap route
        hops: u64,
        liquidity_score: u64, // Higher is better
        execution_time: u64, // Estimated execution time in seconds
    }

    struct SwapRoute has copy, drop, store {
        path: vector<address>,
        dex_sequence: vector<u8>, // Which DEX to use for each hop
        amounts: vector<u64>, // Amount at each step
        fees: vector<u64>, // Fee at each step
    }

    struct SwapResult has copy, drop {
        input_amount: u64,
        output_amount: u64,
        dex_used: u8,
        price_impact: u64,
        fee_paid: u64,
        timestamp: u64,
        route_taken: vector<address>,
    }

    struct AggregatorConfig has key {
        admin: address,
        fee_recipient: address,
        platform_fee: u64, // in basis points
        max_slippage: u64, // in basis points
        supported_dexs: vector<u8>,
        paused: bool,
        quote_cache_duration: u64,
        max_route_hops: u64,
        min_liquidity_threshold: u64,
    }

    struct SwapEvents has key {
        swap_events: EventHandle<SwapExecutedEvent>,
        quote_events: EventHandle<QuoteRequestedEvent>,
        route_found_events: EventHandle<RouteFoundEvent>,
    }

    struct SwapExecutedEvent has drop, store {
        user: address,
        input_token: address,
        output_token: address,
        input_amount: u64,
        output_amount: u64,
        dex_used: u8,
        timestamp: u64,
        route_taken: vector<address>,
        price_impact: u64,
        fee_paid: u64,
    }

    struct QuoteRequestedEvent has drop, store {
        user: address,
        input_token: address,
        output_token: address,
        input_amount: u64,
        quotes_count: u64,
        timestamp: u64,
    }

    struct RouteFoundEvent has drop, store {
        input_token: address,
        output_token: address,
        route: vector<address>,
        dex_sequence: vector<u8>,
        total_fee: u64,
        price_impact: u64,
    }

    struct DEXRegistry has key {
        liquidswap_pools: Table<vector<u8>, PoolInfo>,
        econia_markets: Table<vector<u8>, MarketInfo>,
        panora_pools: Table<vector<u8>, PoolInfo>,
        amnis_pools: Table<vector<u8>, PoolInfo>,
        animeswap_pools: Table<vector<u8>, PoolInfo>,
        sushiswap_pools: Table<vector<u8>, PoolInfo>,
        supported_tokens: Table<address, bool>,
        token_pairs: Table<vector<u8>, vector<SwapRoute>>,
    }

    struct PoolInfo has copy, drop, store {
        liquidity: u64,
        fee: u64, // in basis points
        last_updated: u64,
        is_active: bool,
    }

    struct MarketInfo has copy, drop, store {
        liquidity: u64,
        fee: u64, // in basis points
        last_updated: u64,
        is_active: bool,
        market_id: u64,
    }

    struct QuoteCache has key {
        quotes: Table<vector<u8>, CachedQuote>,
    }

    struct CachedQuote has copy, drop, store {
        quote: SwapQuote,
        timestamp: u64,
    }

    // Initialize the aggregator
    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        move_to(admin, AggregatorConfig {
            admin: admin_addr,
            fee_recipient: admin_addr,
            platform_fee: 30, // 0.3%
            max_slippage: 500, // 5%
            supported_dexs: vector[DEX_LIQUIDSWAP, DEX_ECONIA, DEX_PANORA, DEX_AMNIS, DEX_ANIMESWAP, DEX_SUSHISWAP],
            paused: false,
            quote_cache_duration: QUOTE_EXPIRY_TIME,
            max_route_hops: MAX_HOPS,
            min_liquidity_threshold: MIN_LIQUIDITY_THRESHOLD,
        });

        move_to(admin, SwapEvents {
            swap_events: account::new_event_handle<SwapExecutedEvent>(admin),
            quote_events: account::new_event_handle<QuoteRequestedEvent>(admin),
            route_found_events: account::new_event_handle<RouteFoundEvent>(admin),
        });

        move_to(admin, DEXRegistry {
            liquidswap_pools: table::new(),
            econia_markets: table::new(),
            panora_pools: table::new(),
            amnis_pools: table::new(),
            animeswap_pools: table::new(),
            sushiswap_pools: table::new(),
            supported_tokens: table::new(),
            token_pairs: table::new(),
        });

        move_to(admin, QuoteCache {
            quotes: table::new(),
        });
    }

    // Get best quote with multi-hop routing
    #[view]
    public fun get_best_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): SwapQuote acquires AggregatorConfig, DEXRegistry, QuoteCache {
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(!config.paused, E_SWAP_FAILED);

        // Check cache first
        let cache_key = create_quote_cache_key<InputCoin, OutputCoin>(input_amount);
        let cache = borrow_global<QuoteCache>(@aggregator);
        if (table::contains(&cache.quotes, cache_key)) {
            let cached_quote = table::borrow(&cache.quotes, cache_key);
            if (timestamp::now_seconds() - cached_quote.timestamp < config.quote_cache_duration) {
                return cached_quote.quote
            }
        };

        let quotes = vector::empty<SwapQuote>();
        
        // Get direct quotes
        let direct_quotes = get_direct_quotes<InputCoin, OutputCoin>(input_amount);
        vector::append(&mut quotes, direct_quotes);

        // Get multi-hop quotes
        let multi_hop_quotes = get_multi_hop_quotes<InputCoin, OutputCoin>(input_amount);
        vector::append(&mut quotes, multi_hop_quotes);

        // If no quotes found, create a fallback quote
        if (vector::is_empty(&quotes)) {
            let fallback_quote = create_fallback_quote<InputCoin, OutputCoin>(input_amount);
            vector::push_back(&mut quotes, fallback_quote);
        };
        
        let best_quote = find_best_quote(&quotes);
        
        // Cache the quote
        let cache = borrow_global_mut<QuoteCache>(@aggregator);
        table::add(&mut cache.quotes, cache_key, CachedQuote {
            quote: best_quote,
            timestamp: timestamp::now_seconds(),
        });

        best_quote
    }

    // Create a fallback quote when no pools are available
    fun create_fallback_quote<InputCoin, OutputCoin>(input_amount: u64): SwapQuote {
        // Simple 1:1 swap with minimal fee for testing
        let output_amount = (input_amount * 995) / 1000; // 0.5% fee
        
        SwapQuote {
            dex_id: DEX_LIQUIDSWAP,
            input_amount,
            output_amount,
            price_impact: 50, // 0.5%
            fee: 50, // 0.5%
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 1,
            liquidity_score: 1000000, // Default liquidity
            execution_time: 1,
        }
    }

    // Get direct quotes from all DEXs
    fun get_direct_quotes<InputCoin, OutputCoin>(
        input_amount: u64
    ): vector<SwapQuote> acquires AggregatorConfig, DEXRegistry {
        let config = borrow_global<AggregatorConfig>(@aggregator);
        let quotes = vector::empty<SwapQuote>();
        
        // Query Liquidswap
        if (vector::contains(&config.supported_dexs, &DEX_LIQUIDSWAP)) {
            let liquidswap_quote = get_liquidswap_quote<InputCoin, OutputCoin>(input_amount);
            if (option::is_some(&liquidswap_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut liquidswap_quote));
            };
        };

        // Query Econia
        if (vector::contains(&config.supported_dexs, &DEX_ECONIA)) {
            let econia_quote = get_econia_quote<InputCoin, OutputCoin>(input_amount);
            if (option::is_some(&econia_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut econia_quote));
            };
        };

        // Query Panora
        if (vector::contains(&config.supported_dexs, &DEX_PANORA)) {
            let panora_quote = get_panora_quote<InputCoin, OutputCoin>(input_amount);
            if (option::is_some(&panora_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut panora_quote));
            };
        };

        // Query Amnis
        if (vector::contains(&config.supported_dexs, &DEX_AMNIS)) {
            let amnis_quote = get_amnis_quote<InputCoin, OutputCoin>(input_amount);
            if (option::is_some(&amnis_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut amnis_quote));
            };
        };

        // Query AnimeSwap
        if (vector::contains(&config.supported_dexs, &DEX_ANIMESWAP)) {
            let animeswap_quote = get_animeswap_quote<InputCoin, OutputCoin>(input_amount);
            if (option::is_some(&animeswap_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut animeswap_quote));
            };
        };

        // Query SushiSwap
        if (vector::contains(&config.supported_dexs, &DEX_SUSHISWAP)) {
            let sushiswap_quote = get_sushiswap_quote<InputCoin, OutputCoin>(input_amount);
            if (option::is_some(&sushiswap_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut sushiswap_quote));
            };
        };

        // XÓA: Query PancakeSwap
        // if (vector::contains(&config.supported_dexs, &DEX_PANCAKESWAP)) {
        //     let pancakeswap_quote = get_pancakeswap_quote<InputCoin, OutputCoin>(input_amount);
        //     if (option::is_some(&pancakeswap_quote)) {
        //         vector::push_back(&mut quotes, option::extract(&mut pancakeswap_quote));
        //     };
        // };

        quotes
    }

    // Get multi-hop quotes through intermediate tokens
    fun get_multi_hop_quotes<InputCoin, OutputCoin>(
        input_amount: u64
    ): vector<SwapQuote> {
        let quotes = vector::empty<SwapQuote>();
        
        // Common intermediate tokens (using hardcoded addresses)
        let intermediate_tokens = vector[
            @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // APT
            @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // USDC placeholder
            @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // USDT placeholder
        ];

        let i = 0;
        while (i < vector::length(&intermediate_tokens)) {
            let intermediate = *vector::borrow(&intermediate_tokens, i);
            
            // Skip if intermediate is same as input or output (simplified check)
            // For now, we'll just use the intermediate token
            let multi_hop_quote = calculate_multi_hop_quote<InputCoin, OutputCoin>(
                input_amount, 
                intermediate
            );
            if (option::is_some(&multi_hop_quote)) {
                vector::push_back(&mut quotes, option::extract(&mut multi_hop_quote));
            };
            i = i + 1;
        };

        quotes
    }

    // Calculate multi-hop quote through intermediate token
    fun calculate_multi_hop_quote<InputCoin, OutputCoin>(
        input_amount: u64,
        intermediate_token: address
    ): Option<SwapQuote> {
        // This would calculate the best route through the intermediate token
        // For now, we'll simulate this calculation
        
        // Check if both legs have sufficient liquidity
        let first_leg_liquidity = get_pool_liquidity<InputCoin>(intermediate_token);
        let second_leg_liquidity = get_pool_liquidity<OutputCoin>(intermediate_token);
        
        if (first_leg_liquidity < MIN_LIQUIDITY_THRESHOLD || second_leg_liquidity < MIN_LIQUIDITY_THRESHOLD) {
            return option::none()
        };

        // Simulate multi-hop calculation
        let intermediate_amount = (input_amount * 997) / 1000; // First swap
        let output_amount = (intermediate_amount * 997) / 1000; // Second swap
        
        let total_fee = 60; // Combined fees
        let price_impact = 25; // Higher impact for multi-hop
        
        option::some(SwapQuote {
            dex_id: DEX_LIQUIDSWAP, // Use best DEX for multi-hop
            input_amount,
            output_amount,
            price_impact,
            fee: total_fee,
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                intermediate_token,
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 2,
            liquidity_score: (first_leg_liquidity + second_leg_liquidity) / 2,
            execution_time: 3, // Multi-hop takes longer
        })
    }

    // Find the best quote from a list of quotes
    fun find_best_quote(quotes: &vector<SwapQuote>): SwapQuote {
        let best_quote = *vector::borrow(quotes, 0);
        let best_score = calculate_quote_score(&best_quote);
        
        let i = 1;
        while (i < vector::length(quotes)) {
            let current_quote = *vector::borrow(quotes, i);
            let current_score = calculate_quote_score(&current_quote);
            
            if (current_score > best_score) {
                best_quote = current_quote;
                best_score = current_score;
            };
            i = i + 1;
        };

        best_quote
    }

    // Calculate a score for a quote (higher is better)
    fun calculate_quote_score(quote: &SwapQuote): u64 {
        let output_score = quote.output_amount * 1000; // Primary factor
        let liquidity_bonus = quote.liquidity_score * 10; // Liquidity bonus
        let fee_penalty = quote.fee * 5; // Fee penalty
        let impact_penalty = quote.price_impact * 2; // Price impact penalty
        let time_penalty = quote.execution_time * 100; // Execution time penalty
        
        output_score + liquidity_bonus - fee_penalty - impact_penalty - time_penalty
    }

    // Execute swap using the best available route
    public entry fun swap_exact_input<InputCoin, OutputCoin>(
        user: &signer,
        input_amount: u64,
        min_output_amount: u64,
        deadline: u64
    ) acquires AggregatorConfig, SwapEvents, DEXRegistry, QuoteCache {
        let user_addr = signer::address_of(user);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        
        // Check deadline
        assert!(timestamp::now_seconds() <= deadline, E_DEADLINE_EXCEEDED);
        assert!(!config.paused, E_SWAP_FAILED);
        assert!(input_amount > 0, E_INSUFFICIENT_AMOUNT);

        // Extract config values before calling get_best_quote
        let platform_fee = config.platform_fee;
        let fee_recipient = config.fee_recipient;

        // Get best quote
        let best_quote = get_best_quote<InputCoin, OutputCoin>(input_amount);
        
        // Check slippage
        assert!(best_quote.output_amount >= min_output_amount, E_SLIPPAGE_EXCEEDED);

        // Withdraw input coins from user
        let input_coins = coin::withdraw<InputCoin>(user, input_amount);
        
        // Execute swap based on route
        let output_coins = execute_swap_route<InputCoin, OutputCoin>(input_coins, &best_quote);

        let output_amount = coin::value(&output_coins);
        
        // Calculate and deduct platform fee using local variable
        let platform_fee_amount = (output_amount * platform_fee) / 10000;
        let fee_coins = coin::extract(&mut output_coins, platform_fee_amount);
        
        // Deposit fee to fee recipient using local variable
        coin::deposit(fee_recipient, fee_coins);
        
        // Deposit remaining output coins to user
        coin::deposit(user_addr, output_coins);

        // Emit swap event
        let events = borrow_global_mut<SwapEvents>(@aggregator);
        event::emit_event(&mut events.swap_events, SwapExecutedEvent {
            user: user_addr,
            input_token: @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
            output_token: @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            input_amount,
            output_amount: output_amount - platform_fee_amount,
            dex_used: best_quote.dex_id,
            timestamp: timestamp::now_seconds(),
            route_taken: best_quote.route,
            price_impact: best_quote.price_impact,
            fee_paid: best_quote.fee + platform_fee_amount,
        });
    }

    // Execute swap from sender to receiver with proper coin handling
    public entry fun swap_cross_address_v2<InputCoin, OutputCoin>(
        sender: &signer,
        receiver: address,
        input_amount: u64,
        min_output_amount: u64,
        deadline: u64
    ) acquires AggregatorConfig, SwapEvents, DEXRegistry, QuoteCache {
        let sender_addr = signer::address_of(sender);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        
        // Check deadline
        assert!(timestamp::now_seconds() <= deadline, E_DEADLINE_EXCEEDED);
        assert!(!config.paused, E_SWAP_FAILED);
        assert!(input_amount > 0, E_INSUFFICIENT_AMOUNT);

        // Extract config values before calling get_best_quote
        let platform_fee = config.platform_fee;
        let fee_recipient = config.fee_recipient;

        // Get best quote
        let best_quote = get_best_quote<InputCoin, OutputCoin>(input_amount);
        
        // Check slippage
        assert!(best_quote.output_amount >= min_output_amount, E_SLIPPAGE_EXCEEDED);

        // Withdraw input coins from sender
        let input_coins = coin::withdraw<InputCoin>(sender, input_amount);
        
        // Simulate swap execution - for now, we'll just transfer the input coins to the receiver
        // In a real implementation, this would execute the actual swap
        let output_coins = simulate_swap_execution<InputCoin, OutputCoin>(input_coins, &best_quote);

        let output_amount = coin::value(&output_coins);
        
        // Calculate and deduct platform fee
        let platform_fee_amount = (output_amount * platform_fee) / 10000;
        let fee_coins = coin::extract(&mut output_coins, platform_fee_amount);
        
        // Deposit fee to fee recipient
        coin::deposit(fee_recipient, fee_coins);
        
        // Deposit remaining output coins to receiver
        coin::deposit(receiver, output_coins);

        // Emit swap event
        let events = borrow_global_mut<SwapEvents>(@aggregator);
        event::emit_event(&mut events.swap_events, SwapExecutedEvent {
            user: sender_addr,
            input_token: @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
            output_token: @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            input_amount,
            output_amount: output_amount - platform_fee_amount,
            dex_used: best_quote.dex_id,
            timestamp: timestamp::now_seconds(),
            route_taken: best_quote.route,
            price_impact: best_quote.price_impact,
            fee_paid: best_quote.fee + platform_fee_amount,
        });
    }

    // Simulate swap execution without destroying input coins
    fun simulate_swap_execution<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let _input_amount = coin::value(&input_coins);
        let _output_amount = quote.output_amount;
        
        // For simulation purposes, we'll create zero output coins
        // In a real implementation, this would:
        // 1. Send input_coins to the DEX
        // 2. Receive output_coins from the DEX
        // 3. Return the actual output coins
        
        // For now, we'll just return zero coins to simulate the swap
        // We need to consume the input_coins to avoid the drop error
        coin::destroy_zero(input_coins);
        coin::zero<OutputCoin>()
    }

    // Execute swap through the specified route
    fun execute_swap_route<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        if (quote.hops == 1) {
            if (quote.dex_id == DEX_LIQUIDSWAP) {
                execute_liquidswap_swap<InputCoin, OutputCoin>(input_coins, quote)
            } else if (quote.dex_id == DEX_ECONIA) {
                execute_econia_swap<InputCoin, OutputCoin>(input_coins, quote)
            } else if (quote.dex_id == DEX_PANORA) {
                execute_panora_swap<InputCoin, OutputCoin>(input_coins, quote)
            } else if (quote.dex_id == DEX_AMNIS) {
                execute_amnis_swap<InputCoin, OutputCoin>(input_coins, quote)
            } else if (quote.dex_id == DEX_ANIMESWAP) {
                execute_animeswap_swap<InputCoin, OutputCoin>(input_coins, quote)
            } else if (quote.dex_id == DEX_SUSHISWAP) {
                execute_sushiswap_swap<InputCoin, OutputCoin>(input_coins, quote)
            } else {
                abort E_INVALID_DEX
            }
        } else {
            execute_multi_hop_swap<InputCoin, OutputCoin>(input_coins, quote)
        }
    }

    // Execute multi-hop swap
    fun execute_multi_hop_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Execute swap on Liquidswap (hybrid approach)
    fun execute_liquidswap_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Execute swap on Econia (simulated for now)
    fun execute_econia_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Execute swap on Panora (simulated for now)
    fun execute_panora_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Execute swap on Amnis (simulated for now)
    fun execute_amnis_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Execute swap on AnimeSwap
    fun execute_animeswap_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Execute swap on SushiSwap
    fun execute_sushiswap_swap<InputCoin, OutputCoin>(
        input_coins: Coin<InputCoin>,
        quote: &SwapQuote
    ): Coin<OutputCoin> {
        let input_amount = coin::value(&input_coins);
        let output_amount = quote.output_amount;
        
        // For now, we'll simulate the swap by destroying input coins and creating output coins
        // This is a simplified approach for testing
        coin::destroy_zero(input_coins);
        
        // Create output coins (this will be zero coins for non-AptosDoge tokens)
        coin::zero<OutputCoin>()
    }

    // Get quote from Liquidswap (mock/fallback)
    fun get_liquidswap_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): Option<SwapQuote> {
        // Không truy vấn trực tiếp pool Liquidswap trên mainnet
        // Có thể trả về option::none() hoặc mock dữ liệu mẫu
        option::none()
    }

    // Get quote from Econia
    fun get_econia_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): Option<SwapQuote> acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let market_key = create_pool_key<InputCoin, OutputCoin>();
        
        if (!table::contains(&registry.econia_markets, market_key)) {
            return option::none()
        };

        let market_info = table::borrow(&registry.econia_markets, market_key);
        if (!market_info.is_active || market_info.liquidity < MIN_LIQUIDITY_THRESHOLD) {
            return option::none()
        };

        // Calculate quote based on market info
        let output_amount = calculate_swap_output(input_amount, market_info.liquidity, market_info.fee);
        let price_impact = calculate_price_impact(input_amount, market_info.liquidity);
        
        option::some(SwapQuote {
            dex_id: DEX_ECONIA,
            input_amount,
            output_amount,
            price_impact,
            fee: market_info.fee,
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 1,
            liquidity_score: market_info.liquidity,
            execution_time: 1,
        })
    }

    // Get quote from Panora
    fun get_panora_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): Option<SwapQuote> acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        
        if (!table::contains(&registry.panora_pools, pool_key)) {
            return option::none()
        };

        let pool_info = table::borrow(&registry.panora_pools, pool_key);
        if (!pool_info.is_active || pool_info.liquidity < MIN_LIQUIDITY_THRESHOLD) {
            return option::none()
        };

        // Calculate quote based on pool info
        let output_amount = calculate_swap_output(input_amount, pool_info.liquidity, pool_info.fee);
        let price_impact = calculate_price_impact(input_amount, pool_info.liquidity);
        
        option::some(SwapQuote {
            dex_id: DEX_PANORA,
            input_amount,
            output_amount,
            price_impact,
            fee: pool_info.fee,
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 1,
            liquidity_score: pool_info.liquidity,
            execution_time: 1,
        })
    }

    // Get quote from Amnis
    fun get_amnis_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): Option<SwapQuote> acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        
        if (!table::contains(&registry.amnis_pools, pool_key)) {
            return option::none()
        };

        let pool_info = table::borrow(&registry.amnis_pools, pool_key);
        if (!pool_info.is_active || pool_info.liquidity < MIN_LIQUIDITY_THRESHOLD) {
            return option::none()
        };

        // Calculate quote based on pool info
        let output_amount = calculate_swap_output(input_amount, pool_info.liquidity, pool_info.fee);
        let price_impact = calculate_price_impact(input_amount, pool_info.liquidity);
        
        option::some(SwapQuote {
            dex_id: DEX_AMNIS,
            input_amount,
            output_amount,
            price_impact,
            fee: pool_info.fee,
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 1,
            liquidity_score: pool_info.liquidity,
            execution_time: 1,
        })
    }

    // Get quote from AnimeSwap
    fun get_animeswap_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): Option<SwapQuote> acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        
        if (!table::contains(&registry.animeswap_pools, pool_key)) {
            return option::none()
        };

        let pool_info = table::borrow(&registry.animeswap_pools, pool_key);
        if (!pool_info.is_active || pool_info.liquidity < MIN_LIQUIDITY_THRESHOLD) {
            return option::none()
        };

        // Calculate quote based on pool info
        let output_amount = calculate_swap_output(input_amount, pool_info.liquidity, pool_info.fee);
        let price_impact = calculate_price_impact(input_amount, pool_info.liquidity);
        
        option::some(SwapQuote {
            dex_id: DEX_ANIMESWAP,
            input_amount,
            output_amount,
            price_impact,
            fee: pool_info.fee,
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 1,
            liquidity_score: pool_info.liquidity,
            execution_time: 1,
        })
    }

    // Get quote from SushiSwap
    fun get_sushiswap_quote<InputCoin, OutputCoin>(
        input_amount: u64
    ): Option<SwapQuote> acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        
        if (!table::contains(&registry.sushiswap_pools, pool_key)) {
            return option::none()
        };

        let pool_info = table::borrow(&registry.sushiswap_pools, pool_key);
        if (!pool_info.is_active || pool_info.liquidity < MIN_LIQUIDITY_THRESHOLD) {
            return option::none()
        };

        // Calculate quote based on pool info
        let output_amount = calculate_swap_output(input_amount, pool_info.liquidity, pool_info.fee);
        let price_impact = calculate_price_impact(input_amount, pool_info.liquidity);
        
        option::some(SwapQuote {
            dex_id: DEX_SUSHISWAP,
            input_amount,
            output_amount,
            price_impact,
            fee: pool_info.fee,
            route: vector[
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Input token placeholder
                @0x13a0e1a314426849cf4ac86edb586b38e6271c1245242077c4a873b4bdc942c9, // Output token placeholder
            ],
            hops: 1,
            liquidity_score: pool_info.liquidity,
            execution_time: 1,
        })
    }

    // Calculate swap output amount
    fun calculate_swap_output(input_amount: u64, liquidity: u64, fee: u64): u64 {
        let fee_amount = (input_amount * fee) / 10000;
        let amount_after_fee = input_amount - fee_amount;
        
        // Simple constant product formula (x * y = k)
        // This is a simplified calculation
        (amount_after_fee * liquidity) / (liquidity + amount_after_fee)
    }

    // Calculate price impact
    fun calculate_price_impact(input_amount: u64, liquidity: u64): u64 {
        // Price impact = (input_amount / liquidity) * 10000
        (input_amount * 10000) / liquidity
    }

    // Get pool liquidity for a token pair
    fun get_pool_liquidity<CoinType>(other_token: address): u64 {
        // This would query actual pool liquidity
        // For now, return a default value
        1000000 // 1M liquidity
    }

    // Helper function to create pool key
    fun create_pool_key<InputCoin, OutputCoin>(): vector<u8> {
        let input_type = type_info::type_of<InputCoin>();
        let output_type = type_info::type_of<OutputCoin>();
        
        let key = vector::empty<u8>();
        vector::append(&mut key, bcs::to_bytes(&input_type));
        vector::append(&mut key, bcs::to_bytes(&output_type));
        key
    }

    // Helper function to create quote cache key
    fun create_quote_cache_key<InputCoin, OutputCoin>(input_amount: u64): vector<u8> {
        let key = create_pool_key<InputCoin, OutputCoin>();
        vector::append(&mut key, bcs::to_bytes(&input_amount));
        key
    }

    // Admin functions
    public entry fun update_config(
        admin: &signer,
        fee_recipient: address,
        platform_fee: u64,
        max_slippage: u64,
        quote_cache_duration: u64,
        max_route_hops: u64,
        min_liquidity_threshold: u64
    ) acquires AggregatorConfig {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        config.fee_recipient = fee_recipient;
        config.platform_fee = platform_fee;
        config.max_slippage = max_slippage;
        config.quote_cache_duration = quote_cache_duration;
        config.max_route_hops = max_route_hops;
        config.min_liquidity_threshold = min_liquidity_threshold;
    }

    public entry fun pause(admin: &signer) acquires AggregatorConfig {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        config.paused = true;
    }

    public entry fun unpause(admin: &signer) acquires AggregatorConfig {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        config.paused = false;
    }

    // Add supported token
    public entry fun add_supported_token(
        admin: &signer,
        token_address: address
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.supported_tokens, token_address, true);
    }

    // Add Liquidswap pool
    public entry fun add_liquidswap_pool(
        admin: &signer,
        pool_key: vector<u8>,
        liquidity: u64,
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.liquidswap_pools, pool_key, PoolInfo {
            liquidity,
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }
    
    // Add real Liquidswap pool with actual pool address
    public entry fun add_real_liquidswap_pool<InputCoin, OutputCoin>(
        admin: &signer,
        pool_address: address,
        curve_type: u64, // 0 = UncorrelatedCurve, 1 = StableCurve
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        
        // TODO: Get actual liquidity from the pool when Liquidswap integration is complete
        // For now, use estimated liquidity based on pool address
        let liquidity = 10000000; // 10M liquidity estimate
        
        table::add(&mut registry.liquidswap_pools, pool_key, PoolInfo {
            liquidity,
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add Econia market
    public entry fun add_econia_market(
        admin: &signer,
        market_key: vector<u8>,
        liquidity: u64,
        fee: u64,
        market_id: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.econia_markets, market_key, MarketInfo {
            liquidity,
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
            market_id,
        });
    }
    
    // Setup default pools for testing
    public entry fun setup_default_pools(admin: &signer) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        
        // Add APT/WBTC pool for Liquidswap
        let apt_wbtc_key = create_pool_key<AptosCoin, WBTC>();
        table::add(&mut registry.liquidswap_pools, apt_wbtc_key, PoolInfo {
            liquidity: 100000000, // 100M liquidity
            fee: 30, // 0.3%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
        
        // Add WBTC/APT pool (reverse) for Liquidswap
        let wbtc_apt_key = create_pool_key<WBTC, AptosCoin>();
        table::add(&mut registry.liquidswap_pools, wbtc_apt_key, PoolInfo {
            liquidity: 100000000, // 100M liquidity
            fee: 30, // 0.3%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add APT/WBTC pool for Panora
        let panora_apt_wbtc_key = create_pool_key<AptosCoin, WBTC>();
        table::add(&mut registry.panora_pools, panora_apt_wbtc_key, PoolInfo {
            liquidity: 80000000, // 80M liquidity
            fee: 25, // 0.25%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add WBTC/APT pool (reverse) for Panora
        let panora_wbtc_apt_key = create_pool_key<WBTC, AptosCoin>();
        table::add(&mut registry.panora_pools, panora_wbtc_apt_key, PoolInfo {
            liquidity: 80000000, // 80M liquidity
            fee: 25, // 0.25%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add APT/WBTC pool for Amnis
        let amnis_apt_wbtc_key = create_pool_key<AptosCoin, WBTC>();
        table::add(&mut registry.amnis_pools, amnis_apt_wbtc_key, PoolInfo {
            liquidity: 60000000, // 60M liquidity
            fee: 20, // 0.2%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add WBTC/APT pool (reverse) for Amnis
        let amnis_wbtc_apt_key = create_pool_key<WBTC, AptosCoin>();
        table::add(&mut registry.amnis_pools, amnis_wbtc_apt_key, PoolInfo {
            liquidity: 60000000, // 60M liquidity
            fee: 20, // 0.2%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add Panora pool
    public entry fun add_panora_pool(
        admin: &signer,
        pool_key: vector<u8>,
        curve_type: u64, // 0 = UncorrelatedCurve, 1 = StableCurve
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.panora_pools, pool_key, PoolInfo {
            liquidity: 10000000, // 10M liquidity estimate
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add Amnis pool
    public entry fun add_amnis_pool(
        admin: &signer,
        pool_key: vector<u8>,
        curve_type: u64, // 0 = UncorrelatedCurve, 1 = StableCurve
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.amnis_pools, pool_key, PoolInfo {
            liquidity: 10000000, // 10M liquidity estimate
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add AnimeSwap pool
    public entry fun add_animeswap_pool(
        admin: &signer,
        pool_key: vector<u8>,
        curve_type: u64, // 0 = UncorrelatedCurve, 1 = StableCurve
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.animeswap_pools, pool_key, PoolInfo {
            liquidity: 9966270, // ~$9,966.27 liquidity from GeckoTerminal
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add SushiSwap pool
    public entry fun add_sushiswap_pool(
        admin: &signer,
        pool_key: vector<u8>,
        curve_type: u64, // 0 = UncorrelatedCurve, 1 = StableCurve
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        table::add(&mut registry.sushiswap_pools, pool_key, PoolInfo {
            liquidity: 13784920, // ~$13,784.92 liquidity from GeckoTerminal
            fee,
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add APT/USDC pools for all DEXs
    public entry fun add_apt_usdc_pools(
        admin: &signer
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        
        // Add APT/USDC pool for Liquidswap
        let apt_usdc_key = create_pool_key<AptosCoin, USDC>();
        table::add(&mut registry.liquidswap_pools, apt_usdc_key, PoolInfo {
            liquidity: 50000000, // 50M liquidity
            fee: 30, // 0.3%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
        
        // Add USDC/APT pool (reverse) for Liquidswap
        let usdc_apt_key = create_pool_key<USDC, AptosCoin>();
        table::add(&mut registry.liquidswap_pools, usdc_apt_key, PoolInfo {
            liquidity: 50000000, // 50M liquidity
            fee: 30, // 0.3%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add APT/USDC pool for Panora
        let panora_apt_usdc_key = create_pool_key<AptosCoin, USDC>();
        table::add(&mut registry.panora_pools, panora_apt_usdc_key, PoolInfo {
            liquidity: 40000000, // 40M liquidity
            fee: 25, // 0.25%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add USDC/APT pool (reverse) for Panora
        let panora_usdc_apt_key = create_pool_key<USDC, AptosCoin>();
        table::add(&mut registry.panora_pools, panora_usdc_apt_key, PoolInfo {
            liquidity: 40000000, // 40M liquidity
            fee: 25, // 0.25%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add APT/USDC pool for Amnis
        let amnis_apt_usdc_key = create_pool_key<AptosCoin, USDC>();
        table::add(&mut registry.amnis_pools, amnis_apt_usdc_key, PoolInfo {
            liquidity: 30000000, // 30M liquidity
            fee: 20, // 0.2%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });

        // Add USDC/APT pool (reverse) for Amnis
        let amnis_usdc_apt_key = create_pool_key<USDC, AptosCoin>();
        table::add(&mut registry.amnis_pools, amnis_usdc_apt_key, PoolInfo {
            liquidity: 30000000, // 30M liquidity
            fee: 20, // 0.2%
            last_updated: timestamp::now_seconds(),
            is_active: true,
        });
    }

    // Add real APT/USDC pool with actual pool address
    public entry fun add_real_apt_usdc_pool(
        admin: &signer,
        pool_address: address,
        dex_id: u8, // 1 = Liquidswap, 3 = Panora, 4 = Amnis, 5 = AnimeSwap, 6 = SushiSwap
        fee: u64
    ) acquires AggregatorConfig, DEXRegistry {
        let admin_addr = signer::address_of(admin);
        let config = borrow_global<AggregatorConfig>(@aggregator);
        assert!(config.admin == admin_addr, E_NOT_ADMIN);
        
        let registry = borrow_global_mut<DEXRegistry>(@aggregator);
        let apt_usdc_key = create_pool_key<AptosCoin, USDC>();
        let usdc_apt_key = create_pool_key<USDC, AptosCoin>();
        
        // TODO: Get actual liquidity from the pool when integration is complete
        // For now, use estimated liquidity based on pool address
        let liquidity = 50000000; // 50M liquidity estimate
        
        if (dex_id == DEX_LIQUIDSWAP) {
            table::add(&mut registry.liquidswap_pools, apt_usdc_key, PoolInfo {
                liquidity,
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
            table::add(&mut registry.liquidswap_pools, usdc_apt_key, PoolInfo {
                liquidity,
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
        } else if (dex_id == DEX_PANORA) {
            table::add(&mut registry.panora_pools, apt_usdc_key, PoolInfo {
                liquidity,
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
            table::add(&mut registry.panora_pools, usdc_apt_key, PoolInfo {
                liquidity,
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
        } else if (dex_id == DEX_AMNIS) {
            table::add(&mut registry.amnis_pools, apt_usdc_key, PoolInfo {
                liquidity,
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
            table::add(&mut registry.amnis_pools, usdc_apt_key, PoolInfo {
                liquidity,
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
        } else if (dex_id == DEX_ANIMESWAP) {
            table::add(&mut registry.animeswap_pools, apt_usdc_key, PoolInfo {
                liquidity: 9966270, // ~$9,966.27 liquidity from GeckoTerminal
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
            table::add(&mut registry.animeswap_pools, usdc_apt_key, PoolInfo {
                liquidity: 9966270, // ~$9,966.27 liquidity from GeckoTerminal
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
        } else if (dex_id == DEX_SUSHISWAP) {
            table::add(&mut registry.sushiswap_pools, apt_usdc_key, PoolInfo {
                liquidity: 13784920, // ~$13,784.92 liquidity from GeckoTerminal
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
            table::add(&mut registry.sushiswap_pools, usdc_apt_key, PoolInfo {
                liquidity: 13784920, // ~$13,784.92 liquidity from GeckoTerminal
                fee,
                last_updated: timestamp::now_seconds(),
                is_active: true,
            });
        };
    }

    /// TỰ ĐỘNG ADD POOL LIQUIDSWAP APT/USDC MAINNET
    public entry fun add_liquidswap_apt_usdc_pool_mainnet(admin: &signer) acquires AggregatorConfig, DEXRegistry {
        let pool_address = @0x190d44266241744264b964a37b8f09863167a12d3e70cda39376cfb4e3561e12;
        let curve_type = 0u64; // UncorrelatedCurve
        let fee = 30u64; // 0.3%
        Self::add_liquidswap_pool(
            admin,
            create_pool_key<AptosCoin, USDC>(),
            curve_type,
            fee
        );
    }

    /// TỰ ĐỘNG ADD POOL PANORA APT/USDC MAINNET
    public entry fun add_panora_apt_usdc_pool_mainnet(admin: &signer) acquires AggregatorConfig, DEXRegistry {
        let pool_address = @0x1eabed72c53feb3805180a7c8464bc46f1103de1;
        let curve_type = 0u64; // UncorrelatedCurve
        let fee = 25u64; // 0.25%
        Self::add_panora_pool(
            admin,
            create_pool_key<AptosCoin, USDC>(),
            curve_type,
            fee
        );
    }

    /// TỰ ĐỘNG ADD POOL AMNIS APT/USDC MAINNET
    public entry fun add_amnis_apt_usdc_pool_mainnet(admin: &signer) acquires AggregatorConfig, DEXRegistry {
        let pool_address = @0x7e308b8b7c4c2a8e1d5c9961c3c2de142c8a3c6d2e2c1e1b2a3c4d5e6f7a8b9c;
        let curve_type = 0u64; // UncorrelatedCurve
        let fee = 20u64; // 0.2%
        Self::add_amnis_pool(
            admin,
            create_pool_key<AptosCoin, USDC>(),
            curve_type,
            fee
        );
    }

    /// TỰ ĐỘNG ADD POOL ANIMESWAP APT/USDC MAINNET
    public entry fun add_animeswap_apt_usdc_pool_mainnet(admin: &signer) acquires AggregatorConfig, DEXRegistry {
        let pool_address = @0x16fe2df00ea7dde4a63409201f7f4e536bde7bb7335526a35d0511e68aa322c;
        let curve_type = 0u64; // UncorrelatedCurve
        let fee = 25u64; // 0.25%
        Self::add_animeswap_pool(
            admin,
            create_pool_key<AptosCoin, USDC>(),
            curve_type,
            fee
        );
    }

    /// TỰ ĐỘNG ADD POOL SUSHISWAP APT/USDC MAINNET
    public entry fun add_sushiswap_apt_usdc_pool_mainnet(admin: &signer) acquires AggregatorConfig, DEXRegistry {
        let pool_address = @0x31a6675cbe84365bf2b0cbce617ece6c47023ef70826533bde5203d32171dc3c;
        let curve_type = 0u64; // UncorrelatedCurve
        let fee = 30u64; // 0.3%
        Self::add_sushiswap_pool(
            admin,
            create_pool_key<AptosCoin, USDC>(),
            curve_type,
            fee
        );
    }

    // View functions
    #[view]
    public fun get_config(): (address, address, u64, u64, bool, u64, u64, u64) acquires AggregatorConfig {
        let config = borrow_global<AggregatorConfig>(@aggregator);
        (config.admin, config.fee_recipient, config.platform_fee, config.max_slippage, config.paused, config.quote_cache_duration, config.max_route_hops, config.min_liquidity_threshold)
    }

    #[view]
    public fun simulate_swap<InputCoin, OutputCoin>(
        input_amount: u64
    ): (u64, u8, u64, u64, u64, vector<address>) acquires AggregatorConfig, DEXRegistry, QuoteCache {
        let quote = get_best_quote<InputCoin, OutputCoin>(input_amount);
        (quote.output_amount, quote.dex_id, quote.price_impact, quote.fee, quote.hops, quote.route)
    }

    #[view]
    public fun get_quote_details<InputCoin, OutputCoin>(
        input_amount: u64
    ): (u64, u8, u64, u64, u64, vector<address>, u64, u64) acquires AggregatorConfig, DEXRegistry, QuoteCache {
        let quote = get_best_quote<InputCoin, OutputCoin>(input_amount);
        (quote.output_amount, quote.dex_id, quote.price_impact, quote.fee, quote.hops, quote.route, quote.liquidity_score, quote.execution_time)
    }

    #[view]
    public fun is_pool_added_liquidswap<InputCoin, OutputCoin>(): bool acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        table::contains(&registry.liquidswap_pools, pool_key)
    }

    #[view]
    public fun is_pool_added_sushiswap<InputCoin, OutputCoin>(): bool acquires DEXRegistry {
        let registry = borrow_global<DEXRegistry>(@aggregator);
        let pool_key = create_pool_key<InputCoin, OutputCoin>();
        table::contains(&registry.sushiswap_pools, pool_key)
    }
}
