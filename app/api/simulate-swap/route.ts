import { NextRequest, NextResponse } from 'next/server'
import { SDK as AnimeSDK, NetworkType as AnimeNetworkType } from '@animeswap.org/v1-sdk'
import LiquidswapSDK from '@pontem/liquidswap-sdk'
import { AptosClient } from 'aptos'

// Danh sách đầy đủ các DEX trên Aptos
const DEX_LIST = [
  {
    name: 'PancakeSwap',
    address: '0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa',
    fee: '0.30',
    priority: 1
  },
  {
    name: 'Liquidswap',
    address: '0x190d44266241744264b964a37b8f09863167a12d3e70cda39376cfb4e3561e12',
    fee: '0.30',
    priority: 2
  },
  {
    name: 'AnimeSwap',
    address: '0x16fe2df00ea7dde4a63409201f7f4e536bde7bb7335526a35d05111e68aa322c',
    fee: '0.25',
    priority: 2
  },
  {
    name: 'Panora',
    address: '0x1111af3905d49c220e236b657b31c9b8c579f7cd4e3e60a15daaed991fe519de',
    fee: '0.18',
    priority: 3
  },
  {
    name: 'Aries',
    address: '0x9770fa9c725cbd97eb50b2be5f7516aa73cdb28b0baa40e8d09a07c381d1dffb',
    fee: '0.20',
    priority: 4
  },
  {
    name: 'Econia',
    address: '0xc0deb00c405f84c85dc13442e305df75d9b58c5481e6824349a528b0b78d4bb5',
    fee: '0.35',
    priority: 5
  },
  {
    name: 'SushiSwap',
    address: '0x1eabed72c53feb3805120a081dc15963c204dc8d091542592abaf7c356b1c2df',
    fee: '0.30',
    priority: 6
  },
  {
    name: 'Thala',
    address: '0x6f986d146e4a90b828d8c12c14b6f4e003fdff11c8f5e5d2a56e993d3c5d5b5c',
    fee: '0.25',
    priority: 7
  },
  {
    name: 'Aux',
    address: '0xbd35135844473187163ca197ca93b2ab014370587bb0e3b1a3c248c98b9a3a25',
    fee: '0.30',
    priority: 8
  }
]

// Hàm lấy số liệu pool thực tế và tính outputAmount swap APT -> USDC
async function getPoolQuoteAptUsdc(inputAmount: string) {
  const POOL_ADDRESS = "0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa";
  const APT_DECIMALS = 8;
  const USDC_DECIMALS = 6;
  const FEE_BPS = BigInt(30); // 0.3%
  const client = new AptosClient("https://fullnode.mainnet.aptoslabs.com");
  const resources = await client.getAccountResources(POOL_ADDRESS);
  const pool = resources.find((r: any) =>
    r.type && r.type.includes("TokenPairReserve") &&
    r.type.includes("aptos_coin::AptosCoin") &&
    r.type.includes("asset::USDC")
  );
  if (!pool || !pool.data || !pool.data['reserve_x'] || !pool.data['reserve_y']) throw new Error("Pool not found or missing reserves");
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const data = pool.data as any;
  const reserveX = BigInt(data['reserve_x']); // APT
  const reserveY = BigInt(data['reserve_y']); // USDC
  const amountIn = BigInt(inputAmount); // inputAmount là số nguyên octas
  // Công thức AMM x*y=k, fee 0.3%
  const amountInWithFee = amountIn * (BigInt(10000) - FEE_BPS) / BigInt(10000);
  const numerator = amountInWithFee * reserveY;
  const denominator = reserveX + amountInWithFee;
  const amountOut = numerator / denominator;
  // amountOut là tổng số USDC thực nhận được cho inputAmount APT
  return {
    dex: 'PancakeSwap',
    outputAmount: (Number(amountOut) / 1e6).toFixed(6), // Tổng số USDC thực nhận được
    fee: '0.30',
    priceImpact: '0.10',
    route: ['PancakeSwap'],
    hops: 1,
    liquidityScore: 1000000,
    executionTime: 2,
  };
}

// Hàm tạo mock quote cho DEX
function createMockQuote(dex: any, inputAmount: string, inputDecimals: number, outputDecimals: number) {
  const baseAmount = Number(inputAmount) / Math.pow(10, inputDecimals);
  const randomFactor = 0.95 + Math.random() * 0.1; // 95% - 105% của giá gốc
  const outputAmount = (baseAmount * 5.15 * randomFactor).toFixed(6); // Giả sử 1 APT = 5.15 USDC
  
  return {
    dex: dex.name,
    outputAmount: outputAmount,
    fee: dex.fee,
    priceImpact: (Math.random() * 0.5).toFixed(2),
    route: [dex.name],
    hops: 1,
    liquidityScore: 1000000 - (dex.priority * 50000),
    executionTime: Math.floor(Math.random() * 3) + 1,
  };
}

export async function POST(request: NextRequest) {
  try {
    console.log('🚀 API call started')
    const { inputToken, outputToken, inputAmount } = await request.json()

    // Validate input
    if (!inputToken || !outputToken || !inputAmount) {
      console.log('❌ Missing required parameters')
      return NextResponse.json(
        { error: 'Missing required parameters' },
        { status: 400 }
      )
    }

    console.log('📝 Input params:', { inputToken, outputToken, inputAmount })

    // Chuyển inputAmount (octas) về số thập phân (giả sử decimals = 8 cho APT, 6 cho USDC/USDT...)
    const inputDecimals = inputToken.includes('AptosCoin') ? 8 : 6
    const outputDecimals = outputToken.includes('AptosCoin') ? 8 : 6
    const inputAmountDecimal = Number(inputAmount) / Math.pow(10, inputDecimals)

    // Log inputAmount nhận từ frontend
    console.log('[DEBUG] inputAmount from frontend:', inputAmount, 'inputToken:', inputToken, 'outputToken:', outputToken)

    // Đảm bảo inputAmount là số nguyên octas (frontend đã nhân 1e8)
    let inputAmountInt = inputAmount;
    if (typeof inputAmount === 'string' && inputAmount.includes('.')) {
      // Nếu inputAmount là số thực, nhân 1e8
      inputAmountInt = Math.floor(Number(inputAmount) * Math.pow(10, inputDecimals)).toString();
    }
    // Log inputAmountInt thực tế truyền vào pool
    console.log('[DEBUG] inputAmountInt for pool:', inputAmountInt)

    // 0. Thử lấy quote từ smart contract aggregator trước
    let contractQuote = null
    try {
      console.log('🔄 Attempting smart contract call...')
      
      const client = new AptosClient('https://fullnode.mainnet.aptoslabs.com')
      
      // Gọi smart contract để lấy best quote (đã có annotation #[view])
      const result = await client.view({
        function: '0xdc73b5e73610decca7b5821c43885eeb0defe3e8fbc0ce6cc233c8eff00b03fc::multiswap_aggregator_v2::get_best_quote',
        type_arguments: [inputToken, outputToken],
        arguments: [inputAmount],
      })
      
      console.log('✅ Smart contract call successful!')
      console.log('📊 Raw result:', JSON.stringify(result, null, 2))
      
      if (result && Array.isArray(result) && result.length > 0) {
        // Smart contract trả về struct, cần parse theo đúng format
        const quoteData = result[0] as any
        console.log('📋 Parsed quote data:', JSON.stringify(quoteData, null, 2))
        
        // Kiểm tra xem quoteData có đúng format không
        if (quoteData && typeof quoteData === 'object') {
          // Smart contract trả về output_amount với decimals = 6 (USDC)
          const contractOutputAmount = Number(quoteData.output_amount || 0) / Math.pow(10, 6);
          
          contractQuote = {
            dex: `Aggregator (DEX ${quoteData.dex_id || 1})`,
            outputAmount: contractOutputAmount.toFixed(6),
            fee: (Number(quoteData.fee || 0) / 100).toFixed(2), // Convert from basis points
            priceImpact: (Number(quoteData.price_impact || 0) / 100).toFixed(2), // Convert from basis points
            route: quoteData.route || ['Aggregator'],
            hops: quoteData.hops || 1,
            liquidityScore: quoteData.liquidity_score || 1000000,
            executionTime: quoteData.execution_time || 2,
          }
          console.log('🎯 Final contract quote:', contractQuote)
        } else {
          console.log('⚠️ Quote data format is invalid:', quoteData)
        }
      } else {
        console.log('⚠️ Smart contract returned empty or invalid result:', result)
      }
    } catch (e) {
      console.log('❌ Smart contract quote failed:', e)
      console.log('🔍 Error details:', e instanceof Error ? e.message : String(e))
      console.log('🔍 Error stack:', e instanceof Error ? e.stack : 'No stack trace')
    }

    if (contractQuote) {
      console.log('[DEBUG API] contractQuote.outputAmount:', contractQuote.outputAmount, 'inputAmount:', inputAmount, 'inputAmountInt:', inputAmountInt)
    }

    // Sau khi thử lấy contractQuote, nếu contractQuote null hoặc outputAmount < 0.0001, fallback sang lấy pool thực tế
    // Khi fallback sang pool thực tế, truyền inputAmountInt
    if (!contractQuote || Number(contractQuote.outputAmount) < 0.0001) {
      // Chỉ fallback khi swap APT -> USDC
      if (
        inputToken === '0x1::aptos_coin::AptosCoin' &&
        outputToken === '0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDC'
      ) {
        try {
          contractQuote = await getPoolQuoteAptUsdc(inputAmountInt);
          console.log('[DEBUG API] poolQuote.outputAmount:', contractQuote.outputAmount, 'inputAmountInt:', inputAmountInt)
        } catch (e) {
          console.log('❌ Fallback pool quote failed:', e);
        }
      }
    }

    // Tạo danh sách quotes từ tất cả DEX
    const allQuotes = [];
    
    // Tạm thời ẩn Aggregator quote để tránh nhầm lẫn
    // if (contractQuote) {
    //   allQuotes.push(contractQuote);
    // }

    // Thêm quotes từ tất cả DEX trong danh sách
    for (const dex of DEX_LIST) {
      try {
        console.log(`🔄 Attempting ${dex.name} quote...`);
        
        // Tạo mock quote cho mỗi DEX (có thể thay thế bằng real API calls sau)
        const mockQuote = createMockQuote(dex, inputAmount, inputDecimals, outputDecimals);
        allQuotes.push(mockQuote);
        
        console.log(`✅ ${dex.name} quote created:`, mockQuote);
      } catch (error) {
        console.log(`❌ ${dex.name} quote failed:`, error instanceof Error ? error.message : String(error));
      }
    }

    // Tìm best quote (outputAmount cao nhất)
    const bestQuote = allQuotes.reduce((best, current) => {
      return Number(current.outputAmount) > Number(best.outputAmount) ? current : best
    }, allQuotes[0])
    
    const response = {
      quotes: allQuotes,
      bestQuote: bestQuote,
      totalDexCount: DEX_LIST.length + (contractQuote ? 1 : 0)
    }
    
    console.log('✅ Returning aggregated response with', allQuotes.length, 'quotes from', response.totalDexCount, 'DEXs')
    return NextResponse.json(response)

  } catch (error) {
    console.log('💥 API error:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : String(error) },
      { status: 500 }
    )
  }
} 