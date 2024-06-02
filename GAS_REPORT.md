# Gas Report Comparison

|            **Protocol**            |      **Actions / Function**      | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |
| :--------------------------------: | :------------------------------: | :--------------: | :-------------: | :-----------------: | :-----------------: | :----------: | :----------------: |
|               ERC20                |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    49921     |         0          |
|               ERC20                |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    25221     |         0          |
|               ERC20                |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    94767     |         0          |
|               ERC20                |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    74867     |         0          |
|               ERC20                |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    335883    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    315984    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    319073    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    299174    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    367178    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    347278    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    111262    |         0          |
|               ERC20                |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    91363     |         0          |
|               ERC721               |           transferFrom           |       EOA        |      False      |        False        |    🧊 ColdAccess    |    48483     |         0          |
|               ERC721               |           transferFrom           |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28583     |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    98254     |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    78354     |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    334585    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    314685    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    317777    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    297877    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    365881    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    345981    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    114777    |         0          |
|               ERC721               |           transferFrom           |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    94877     |         0          |
|                ETH                 |             transfer             |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53073     |         0          |
|                ETH                 |             transfer             |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28073     |         0          |
|                ETH                 |               call               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53201     |         0          |
|                ETH                 |               call               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28201     |         0          |
|                ETH                 |               send               |       EOA        |      False      |        False        |    🧊 ColdAccess    |    53201     |         0          |
|                ETH                 |               send               |       EOA        |      False      |        False        |    🔥 WarmAccess    |    28201     |         0          |
|                ETH                 |             transfer             |  Smart Account   |      True       |        False        |    🧊 ColdAccess    |    102616    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      True       |        False        |    🔥 WarmAccess    |    77616     |         0          |
|                ETH                 |             transfer             |  Smart Account   |      False      |        True         |    🧊 ColdAccess    |    338898    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      False      |        True         |    🔥 WarmAccess    |    313898    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    322110    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    297110    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      False      |        False        |    🧊 ColdAccess    |    370215    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      False      |        False        |    🔥 WarmAccess    |    345215    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      True       |        True         |    🧊 ColdAccess    |    119101    |         0          |
|                ETH                 |             transfer             |  Smart Account   |      True       |        True         |    🔥 WarmAccess    |    94101     |         0          |
|             UniswapV2              |      swapExactETHForTokens       |       EOA        |      False      |        False        |         N/A         |    149263    |         0          |
|             UniswapV2              |      swapExactETHForTokens       |  Smart Account   |      True       |        False        |         N/A         |    199242    |         0          |
|             UniswapV2              |      swapExactETHForTokens       |  Smart Account   |      False      |        True         |         N/A         |    435648    |         0          |
|             UniswapV2              |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    418767    |         0          |
|             UniswapV2              |      swapExactETHForTokens       |  Smart Account   |      False      |        False        |         N/A         |    466872    |         0          |
|             UniswapV2              |      swapExactETHForTokens       |  Smart Account   |      True       |        True         |         N/A         |    215805    |         0          |
|             UniswapV2              |     swapExactTokensForTokens     |       EOA        |      False      |        False        |         N/A         |    118252    |         0          |
|             UniswapV2              |     swapExactTokensForTokens     |  Smart Account   |      True       |        False        |         N/A         |    168221    |         0          |
|             UniswapV2              |     swapExactTokensForTokens     |  Smart Account   |      False      |        True         |         N/A         |    404616    |         0          |
|             UniswapV2              |     swapExactTokensForTokens     |  Smart Account   |      False      |        False        |         N/A         |    387734    |         0          |
|             UniswapV2              | approve+swapExactTokensForTokens |  Smart Account   |      True       |        False        |         N/A         |    200217    |         0          |
|             UniswapV2              | approve+swapExactTokensForTokens |  Smart Account   |      False      |        True         |         N/A         |    436814    |         0          |
|             UniswapV2              | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    419743    |         0          |
|             UniswapV2              | approve+swapExactTokensForTokens |  Smart Account   |      False      |        False        |         N/A         |    467849    |         0          |
|             UniswapV2              |     swapExactTokensForTokens     |  Smart Account   |      True       |        True         |         N/A         |    184796    |         0          |
| No differences found in gas usage. |
