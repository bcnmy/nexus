# Gas Report Comparison

| **Protocol** |      **Actions / Function**      | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |
| :----------: | :------------------------------: | :--------------: | :-------------: | :-----------------: | :-----------------: | :----------: | :----------------: |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    49374     |         0          |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    24674     |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    91863     |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    71963     |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    360553    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    340653    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    345319    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    325418    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    393345    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    373445    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    106659    |       🥵 +9        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    86758     |       🥵 +9        |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🧊 ColdAccess    |    47585     |         0          |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27685     |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    95190     |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    75290     |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    359076    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    339176    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    343852    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    323952    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    391879    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    371979    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    109995    |       🥵 +9        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    90095     |       🥵 +9        |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52862     |         0          |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27862     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52926     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27926     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    52926     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    27926     |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    99958     |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    74958     |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    363802    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    338802    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    348625    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    323625    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    396651    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    371651    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    114699    |       🥵 +9        |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    89699     |       🥵 +9        |
|  UniswapV2   |      swapExactETHForTokens       |       EOA        |      False      |        False        |         N/A         |    148619    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        False        |         N/A         |    196557    |       🥵 +9        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        True         |         N/A         |    460567    |       🥵 +9        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    445258    |       🥵 +9        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    493285    |       🥵 +9        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        True         |         N/A         |    211462    |       🥵 +9        |
|  UniswapV2   |     swapExactTokensForTokens     |       EOA        |      False      |        False        |         N/A         |    117563    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        False        |         N/A         |    165546    |       🥵 +9        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        True         |         N/A         |    429536    |       🥵 +9        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        False        |         N/A         |    414223    |       🥵 +9        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      True       |        False        |         N/A         |    198111    |       🥵 +42       |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        True         |         N/A         |    462359    |       🥵 +42       |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    446814    |       🥵 +42       |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    494841    |       🥵 +42       |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        True         |         N/A         |    180443    |       🥵 +9        |
