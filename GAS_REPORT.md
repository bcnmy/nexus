# Gas Report Comparison

| **Protocol** |      **Actions / Function**      | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |
| :----------: | :------------------------------: | :--------------: | :-------------: | :-----------------: | :-----------------: | :----------: | :----------------: |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    49429     |      🥳 -492       |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    24729     |      🥳 -492       |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    91671     |      🥳 -3108      |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    71771     |      🥳 -3109      |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    328180    |      🥳 -7684      |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    308280    |      🥳 -7684      |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    313048    |      🥳 -6030      |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    293148    |      🥳 -6030      |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    361075    |      🥳 -6107      |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    341175    |      🥳 -6108      |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    106454    |      🥳 -4833      |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    86554     |      🥳 -4833      |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🧊 ColdAccess    |    47632     |      🥳 -851       |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27732     |      🥳 -851       |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    94998     |      🥳 -3267      |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    75098     |      🥳 -3267      |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    326716    |      🥳 -7837      |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    306816    |      🥳 -7837      |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    311582    |      🥳 -6186      |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    291682    |      🥳 -6186      |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    359608    |      🥳 -6265      |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    339708    |      🥳 -6265      |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    109814    |      🥳 -4988      |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    89914     |      🥳 -4988      |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52882     |      🥳 -191       |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27882     |      🥳 -191       |
|     ETH      |               call               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52946     |      🥳 -255       |
|     ETH      |               call               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27946     |      🥳 -255       |
|     ETH      |               send               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52955     |      🥳 -246       |
|     ETH      |               send               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27946     |      🥳 -255       |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    99766     |      🥳 -2862      |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    74766     |      🥳 -2862      |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    331441    |      🥳 -7449      |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    306441    |      🥳 -7449      |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    316331    |      🥳 -5783      |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    291331    |      🥳 -5783      |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    364358    |      🥳 -5861      |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    339358    |      🥳 -5861      |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    114520    |      🥳 -4593      |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    89520     |      🥳 -4593      |
|  UniswapV2   |      swapExactETHForTokens       |       EOA        |      False      |        False        |         N/A         |    148666    |      🥳 -597       |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        False        |         N/A         |    196378    |      🥳 -2876      |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        True         |         N/A         |    428194    |      🥳 -7434      |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    412962    |      🥳 -5797      |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    460988    |      🥳 -5876      |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        True         |         N/A         |    211244    |      🥳 -4585      |
|  UniswapV2   |     swapExactTokensForTokens     |       EOA        |      False      |        False        |         N/A         |    117590    |      🥳 -662       |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        False        |         N/A         |    165355    |      🥳 -2877      |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        True         |         N/A         |    397174    |      🥳 -7434      |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        False        |         N/A         |    381928    |      🥳 -5798      |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      True       |        False        |         N/A         |    197896    |      🥳 -2334      |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        True         |         N/A         |    429959    |      🥳 -6860      |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    414493    |      🥳 -5256      |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    462519    |      🥳 -5334      |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        True         |         N/A         |    180238    |      🥳 -4582      |
