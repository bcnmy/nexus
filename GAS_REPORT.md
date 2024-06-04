# Gas Report Comparison

| **Protocol** |      **Actions / Function**      | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |
| :----------: | :------------------------------: | :--------------: | :-------------: | :-----------------: | :-----------------: | :----------: | :----------------: |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    49429     |         0          |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    24729     |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    91671     |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    71771     |         0          |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    328180    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    308280    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    313048    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    293148    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    361075    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    341175    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    106454    |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    86554     |         0          |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🧊 ColdAccess    |    47632     |         0          |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27732     |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    94998     |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    75098     |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    326716    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    306816    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    311582    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    291682    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    359608    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    339708    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    109814    |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    89914     |         0          |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52882     |         0          |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27882     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52946     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27946     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52955     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27946     |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    99766     |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    74766     |         0          |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    331441    |         0          |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    306441    |         0          |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    316331    |         0          |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    291331    |         0          |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    364358    |         0          |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    339358    |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    114520    |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    89520     |         0          |
|  UniswapV2   |      swapExactETHForTokens       |       EOA        |      False      |        False        |         N/A         |    148666    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        False        |         N/A         |    196378    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        True         |         N/A         |    428194    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    412962    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    460988    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        True         |         N/A         |    211244    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |       EOA        |      False      |        False        |         N/A         |    117590    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        False        |         N/A         |    165355    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        True         |         N/A         |    397174    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        False        |         N/A         |    381928    |         0          |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      True       |        False        |         N/A         |    197896    |         0          |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        True         |         N/A         |    429959    |         0          |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    414493    |         0          |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    462519    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        True         |         N/A         |    180238    |         0          |
