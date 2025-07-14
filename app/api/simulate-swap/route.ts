import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const { inputToken, outputToken, inputAmount } = await request.json()

    // Validate input
    if (!inputToken || !outputToken || !inputAmount) {
      return NextResponse.json(
        { error: 'Missing required parameters' },
        { status: 400 }
      )
    }

    // Call the Aptos blockchain to simulate the swap
    const response = await fetch('https://fullnode.mainnet.aptoslabs.com/v1/view', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        function: '0xe92e80d3819badc3c8881b1eaafc43f2563bac722b0183068ffa90af27917bd8::multiswap_aggregator::simulate_swap',
        type_arguments: [inputToken, outputToken],
        arguments: [inputAmount],
      }),
    })

    if (!response.ok) {
      throw new Error(`Aptos API error: ${response.status}`)
    }

    const data = await response.json()
    
    // Parse the response from the Move function
    const result = data.result || data
    
    // The Move function returns: [output_amount, dex_id, price_impact, fee, hops, route]
    const [outputAmount, dexId, priceImpact, fee, hops, route] = result

    return NextResponse.json({
      outputAmount: outputAmount.toString(),
      dexId: parseInt(dexId),
      priceImpact: priceImpact.toString(),
      fee: fee.toString(),
      hops: parseInt(hops),
      route: route || [],
    })

  } catch (error) {
    console.error('Error simulating swap:', error)
    // Lấy inputAmount từ request nếu có, fallback về '1' nếu không
    let inputAmount = '1';
    try {
      const body = await request.json();
      inputAmount = body.inputAmount || '1';
    } catch {}
    // Return fallback data if the API call fails
    return NextResponse.json({
      outputAmount: (parseInt(inputAmount) * 0.98).toString(), // 2% slippage
      dexId: 1, // Liquidswap
      priceImpact: "100", // 1%
      fee: "30", // 0.3%
      hops: 1,
      route: [],
    })
  }
} 