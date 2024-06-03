# Gas Report Comparison

| **Protocol** |      **Actions / Function**      | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |
| :----------: | :------------------------------: | :--------------: | :-------------: | :-----------------: | :-----------------: | :----------: | :----------------: |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    49921     |         0          |
|    ERC20     |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    25221     |         0          |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    94779     |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    74880     |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    335864    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    315964    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    319078    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    299178    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    367182    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    347283    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    111287    |       🥵 +7        |
|    ERC20     |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    91387     |       🥵 +7        |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🧊 ColdAccess    |    48483     |         0          |
|    ERC721    |           transferFrom           |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28583     |         0          |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    98265     |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    78365     |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    334553    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    314653    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    317768    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    297868    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    365873    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    345973    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    114802    |       🥵 +7        |
|    ERC721    |           transferFrom           |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    94902     |       🥵 +7        |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53073     |         0          |
|     ETH      |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28073     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53201     |         0          |
|     ETH      |               call               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28201     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53201     |         0          |
|     ETH      |               send               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28201     |         0          |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    102628    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    77628     |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    338890    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    313890    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    322114    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    297114    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    370219    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    345219    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    119113    |       🥵 +7        |
|     ETH      |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    94113     |       🥵 +7        |
|  UniswapV2   |      swapExactETHForTokens       |       EOA        |      False      |        False        |         N/A         |    149263    |         0          |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        False        |         N/A         |    199254    |       🥵 +7        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        True         |         N/A         |    435628    |       🥵 +7        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    418759    |       🥵 +7        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    466864    |       🥵 +7        |
|  UniswapV2   |      swapExactETHForTokens       |  Smart Account   |      True       |        True         |         N/A         |    215829    |       🥵 +7        |
|  UniswapV2   |     swapExactTokensForTokens     |       EOA        |      False      |        False        |         N/A         |    118252    |         0          |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        False        |         N/A         |    168232    |       🥵 +7        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        True         |         N/A         |    404608    |       🥵 +7        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      False      |        False        |         N/A         |    387726    |       🥵 +7        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      True       |        False        |         N/A         |    200230    |       🥵 +7        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        True         |         N/A         |    436819    |       🥵 +7        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    419749    |       🥵 +7        |
|  UniswapV2   | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    467853    |       🥵 +7        |
|  UniswapV2   |     swapExactTokensForTokens     |  Smart Account   |      True       |        True         |         N/A         |    184820    |       🥵 +7        |
