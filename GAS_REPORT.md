# Gas Report Comparison

| **Protocol** |      **Actions / Function**      | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |
| :----------: | :------------------------------: | :--------------: | :-------------: | :-----------------: | :-----------------: | :----------: | :----------------: |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    49921     |         0          |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    25221     |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    94772     |       🥵 +5        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    74873     |       🥵 +6        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    335857    |       🥳 -26       |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    315957    |       🥳 -27       |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    319071    |       🥳 -2        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    299171    |       🥳 -3        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    367175    |       🥳 -3        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    347276    |       🥳 -2        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    111280    |       🥵 +18       |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    91380     |       🥵 +17       |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🧊 ColdAccess    |    48483     |         0          |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28583     |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    98258     |       🥵 +4        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    78358     |       🥵 +4        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    334546    |       🥳 -39       |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    314646    |       🥳 -39       |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    317761    |       🥳 -16       |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    297861    |       🥳 -16       |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    365866    |       🥳 -15       |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    345966    |       🥳 -15       |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    114795    |       🥵 +18       |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    94895     |       🥵 +18       |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53073     |         0          |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28073     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53201     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28201     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53201     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28201     |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    102621    |       🥵 +5        |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    77621     |       🥵 +5        |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    338883    |       🥳 -15       |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    313883    |       🥳 -15       |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    322107    |       🥳 -3        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    297107    |       🥳 -3        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    370212    |       🥳 -3        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    345212    |       🥳 -3        |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    119106    |       🥵 +5        |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    94106     |       🥵 +5        |
|  UniswapV2   |      swapExactETHForTokens       |       EOA        |      False      |        False        |         N/A         |    149263    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        False        |         N/A         |    199247    |       🥵 +5        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        True         |         N/A         |    435621    |       🥳 -27       |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    418752    |       🥳 -15       |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    466857    |       🥳 -15       |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        True         |         N/A         |    215822    |       🥵 +17       |
|  UniswapV2   |     swapExactTokensForTokens     |       EOA        |      False      |        False        |         N/A         |    118252    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        False        |         N/A         |    168225    |       🥵 +4        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        True         |         N/A         |    404601    |       🥳 -15       |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        False        |         N/A         |    387719    |       🥳 -15       |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      True       |        False        |         N/A         |    200223    |       🥵 +6        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        True         |         N/A         |    436812    |       🥳 -2        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    419742    |       🥳 -1        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    467846    |       🥳 -3        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        True         |         N/A         |    184813    |       🥵 +17       |
