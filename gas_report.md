# Gas Report
| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Full Log** |
|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:-------------:|
|   ERC20 | transfer | EOA | False | False | 🔥 WarmAccess | 25221 | ERC20::transfer::EOA::Simple::WarmAccess: 25221 |
|   ERC20 | transfer | EOA | False | False | 🧊 ColdAccess | 49921 | ERC20::transfer::EOA::Simple::ColdAccess: 49921 |
|   ERC20 | transfer | Smart Account | True | False | 🔥 WarmAccess | 74867 | ERC20::transfer::Nexus::Deployed::WarmAccess: 74867 |
|   ERC20 | transfer | Smart Account | True | True | 🔥 WarmAccess | 91363 | ERC20::transfer::Nexus::WithPaymaster::WarmAccess: 91363 |
|   ERC20 | transfer | Smart Account | True | False | 🧊 ColdAccess | 94767 | ERC20::transfer::Nexus::Deployed::ColdAccess: 94767 |
|   ERC20 | transfer | Smart Account | True | True | 🧊 ColdAccess | 111262 | ERC20::transfer::Nexus::WithPaymaster::ColdAccess: 111262 |
|   ERC20 | transfer | Smart Account | False | False | 🔥 WarmAccess | 347256 | ERC20::transfer::Setup And Call::Using Pre-Funded Ether::WarmAccess: 347256 |
|   ERC20 | transfer | Smart Account | False | False | 🔥 WarmAccess | 299152 | ERC20::transfer::Setup And Call::UsingDeposit::WarmAccess: 299152 |
|   ERC20 | transfer | Smart Account | False | True | 🔥 WarmAccess | 315962 | ERC20::transfer::Setup And Call::WithPaymaster::WarmAccess: 315962 |
|   ERC20 | transfer | Smart Account | False | False | 🧊 ColdAccess | 367156 | ERC20::transfer::Setup And Call::Using Pre-Funded Ether::ColdAccess: 367156 |
|   ERC20 | transfer | Smart Account | False | False | 🧊 ColdAccess | 319051 | ERC20::transfer::Setup And Call::UsingDeposit::ColdAccess: 319051 |
|   ERC20 | transfer | Smart Account | False | True | 🧊 ColdAccess | 335861 | ERC20::transfer::Setup And Call::WithPaymaster::ColdAccess: 335861 |
|   ERC721 | transferFrom | EOA | False | False | 🔥 WarmAccess | 28583 | ERC721::transferFrom::EOA::Simple::WarmAccess: 28583 |
|   ERC721 | transferFrom | EOA | False | False | 🧊 ColdAccess | 48483 | ERC721::transferFrom::EOA::Simple::ColdAccess: 48483 |
|   ERC721 | transferFrom | Smart Account | True | False | 🔥 WarmAccess | 78354 | ERC721::transferFrom::Nexus::Deployed::WarmAccess: 78354 |
|   ERC721 | transferFrom | Smart Account | True | True | 🔥 WarmAccess | 94877 | ERC721::transferFrom::Nexus::WithPaymaster::WarmAccess: 94877 |
|   ERC721 | transferFrom | Smart Account | True | False | 🧊 ColdAccess | 98254 | ERC721::transferFrom::Nexus::Deployed::ColdAccess: 98254 |
|   ERC721 | transferFrom | Smart Account | True | True | 🧊 ColdAccess | 114777 | ERC721::transferFrom::Nexus::WithPaymaster::ColdAccess: 114777 |
|   ERC721 | transferFrom | Smart Account | False | False | 🔥 WarmAccess | 345959 | ERC721::transferFrom::Setup And Call::Using Pre-Funded Ether::WarmAccess: 345959 |
|   ERC721 | transferFrom | Smart Account | False | False | 🔥 WarmAccess | 297855 | ERC721::transferFrom::Setup And Call::UsingDeposit::WarmAccess: 297855 |
|   ERC721 | transferFrom | Smart Account | False | True | 🔥 WarmAccess | 314664 | ERC721::transferFrom::Setup And Call::WithPaymaster::WarmAccess: 314664 |
|   ERC721 | transferFrom | Smart Account | False | False | 🧊 ColdAccess | 365859 | ERC721::transferFrom::Setup And Call::Using Pre-Funded Ether::ColdAccess: 365859 |
|   ERC721 | transferFrom | Smart Account | False | False | 🧊 ColdAccess | 317755 | ERC721::transferFrom::Setup And Call::UsingDeposit::ColdAccess: 317755 |
|   ERC721 | transferFrom | Smart Account | False | True | 🧊 ColdAccess | 334564 | ERC721::transferFrom::Setup And Call::WithPaymaster::ColdAccess: 334564 |
|   ETH | call | EOA | False | False | 🔥 WarmAccess | 28201 | ETH::call::EOA::Simple::WarmAccess: 28201 |
|   ETH | send | EOA | False | False | 🔥 WarmAccess | 28201 | ETH::send::EOA::Simple::WarmAccess: 28201 |
|   ETH | transfer | EOA | False | False | 🔥 WarmAccess | 28073 | ETH::transfer::EOA::Simple::WarmAccess: 28073 |
|   ETH | call | EOA | False | False | 🧊 ColdAccess | 53201 | ETH::call::EOA::Simple::ColdAccess: 53201 |
|   ETH | send | EOA | False | False | 🧊 ColdAccess | 53201 | ETH::send::EOA::Simple::ColdAccess: 53201 |
|   ETH | transfer | EOA | False | False | 🧊 ColdAccess | 53073 | ETH::transfer::EOA::Simple::ColdAccess: 53073 |
|   ETH | transfer | Smart Account | True | False | 🔥 WarmAccess | 77616 | ETH::transfer::Nexus::Deployed::WarmAccess: 77616 |
|   ETH | transfer | Smart Account | True | True | 🔥 WarmAccess | 94101 | ETH::transfer::Nexus::WithPaymaster::WarmAccess: 94101 |
|   ETH | transfer | Smart Account | True | False | 🧊 ColdAccess | 102616 | ETH::transfer::Nexus::Deployed::ColdAccess: 102616 |
|   ETH | transfer | Smart Account | True | True | 🧊 ColdAccess | 119101 | ETH::transfer::Nexus::WithPaymaster::ColdAccess: 119101 |
|   ETH | transfer | Smart Account | False | False | 🔥 WarmAccess | 345193 | ETH::transfer::Setup And Call::Using Pre-Funded Ether::WarmAccess: 345193 |
|   ETH | transfer | Smart Account | False | False | 🔥 WarmAccess | 297088 | ETH::transfer::Setup And Call::UsingDeposit::WarmAccess: 297088 |
|   ETH | transfer | Smart Account | False | True | 🔥 WarmAccess | 313876 | ETH::transfer::Setup And Call::WithPaymaster::WarmAccess: 313876 |
|   ETH | transfer | Smart Account | False | False | 🧊 ColdAccess | 370193 | ETH::transfer::Setup And Call::Using Pre-Funded Ether::ColdAccess: 370193 |
|   ETH | transfer | Smart Account | False | False | 🧊 ColdAccess | 322088 | ETH::transfer::Setup And Call::UsingDeposit::ColdAccess: 322088 |
|   ETH | transfer | Smart Account | False | True | 🧊 ColdAccess | 338876 | ETH::transfer::Setup And Call::WithPaymaster::ColdAccess: 338876 |
|   UniswapV2 | swapExactTokensForTokens | EOA | False | False | N/A | 118252 | UniswapV2::swapExactTokensForTokens::EOA::WETHtoUSDC::N/A: 118252 |
|   UniswapV2 | swapExactETHForTokens | EOA | False | False | N/A | 149263 | UniswapV2::swapExactETHForTokens::EOA::ETHtoUSDC::N/A: 149263 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | True | False | N/A | 200217 | UniswapV2::approve+swapExactTokensForTokens::Nexus::Deployed::N/A: 200217 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | True | False | N/A | 168221 | UniswapV2::swapExactTokensForTokens::Nexus::Deployed::N/A: 168221 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | True | True | N/A | 184796 | UniswapV2::swapExactTokensForTokens::Nexus::WithPaymaster::N/A: 184796 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | True | False | N/A | 199242 | UniswapV2::swapExactETHForTokens::Nexus::Deployed::N/A: 199242 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | True | True | N/A | 215805 | UniswapV2::swapExactETHForTokens::Nexus::WithPaymaster::N/A: 215805 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | False | False | N/A | 419721 | UniswapV2::approve+swapExactTokensForTokens::Setup And Call::UsingDeposit::N/A: 419721 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | False | True | N/A | 436792 | UniswapV2::approve+swapExactTokensForTokens::Setup And Call::WithPaymaster::N/A: 436792 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | False | False | N/A | 387712 | UniswapV2::swapExactTokensForTokens::Setup And Call::UsingDeposit::N/A: 387712 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | False | True | N/A | 404594 | UniswapV2::swapExactTokensForTokens::Setup And Call::WithPaymaster::N/A: 404594 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | False | False | N/A | 467827 | UniswapV2::approve+swapExactTokensForTokens::Setup And Call::Using Pre-Funded Ether::N/A: 467827 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | False | False | N/A | 418745 | UniswapV2::swapExactETHForTokens::Setup And Call::UsingDeposit::N/A: 418745 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | False | True | N/A | 435626 | UniswapV2::swapExactETHForTokens::Setup And Call::WithPaymaster::N/A: 435626 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | False | False | N/A | 466850 | UniswapV2::swapExactETHForTokens::Setup And Call::Using Pre-Funded Ether::N/A: 466850 |