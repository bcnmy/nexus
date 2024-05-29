# Gas Report
| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Full Log** |
|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:-------------:|
|   ERC20 | transfer | EOA | False | False | 🧊 ColdAccess | 49921 | ERC20::transfer::EOA::Simple::ColdAccess: 49921 |
|   ERC20 | transfer | EOA | False | False | 🔥 WarmAccess | 25221 | ERC20::transfer::EOA::Simple::WarmAccess: 25221 |
|   ERC20 | transfer | Smart Account | True | False | 🧊 ColdAccess | 94755 | ERC20::transfer::Nexus::Deployed::ColdAccess: 94755 |
|   ERC20 | transfer | Smart Account | True | True | 🧊 ColdAccess | 111250 | ERC20::transfer::Nexus::WithPaymaster::ColdAccess: 111250 |
|   ERC20 | transfer | Smart Account | True | False | 🔥 WarmAccess | 74855 | ERC20::transfer::Nexus::Deployed::WarmAccess: 74855 |
|   ERC20 | transfer | Smart Account | True | True | 🔥 WarmAccess | 91351 | ERC20::transfer::Nexus::WithPaymaster::WarmAccess: 91351 |
|   ERC20 | transfer | Smart Account | False | False | 🧊 ColdAccess | 367144 | ERC20::transfer::Setup And Call::Using Pre-Funded Ether::ColdAccess: 367144 |
|   ERC20 | transfer | Smart Account | False | False | 🧊 ColdAccess | 319039 | ERC20::transfer::Setup And Call::UsingDeposit::ColdAccess: 319039 |
|   ERC20 | transfer | Smart Account | False | True | 🧊 ColdAccess | 335849 | ERC20::transfer::Setup And Call::WithPaymaster::ColdAccess: 335849 |
|   ERC20 | transfer | Smart Account | False | False | 🔥 WarmAccess | 347244 | ERC20::transfer::Setup And Call::Using Pre-Funded Ether::WarmAccess: 347244 |
|   ERC20 | transfer | Smart Account | False | False | 🔥 WarmAccess | 299140 | ERC20::transfer::Setup And Call::UsingDeposit::WarmAccess: 299140 |
|   ERC20 | transfer | Smart Account | False | True | 🔥 WarmAccess | 315950 | ERC20::transfer::Setup And Call::WithPaymaster::WarmAccess: 315950 |
|   ERC721 | transferFrom | EOA | False | False | 🔥 WarmAccess | 28583 | ERC721::transferFrom::EOA::Simple::WarmAccess: 28583 |
|   ERC721 | transferFrom | EOA | False | False | 🧊 ColdAccess | 48483 | ERC721::transferFrom::EOA::Simple::ColdAccess: 48483 |
|   ERC721 | transferFrom | Smart Account | True | False | 🔥 WarmAccess | 78342 | ERC721::transferFrom::Nexus::Deployed::WarmAccess: 78342 |
|   ERC721 | transferFrom | Smart Account | True | True | 🔥 WarmAccess | 94865 | ERC721::transferFrom::Nexus::WithPaymaster::WarmAccess: 94865 |
|   ERC721 | transferFrom | Smart Account | True | False | 🧊 ColdAccess | 98242 | ERC721::transferFrom::Nexus::Deployed::ColdAccess: 98242 |
|   ERC721 | transferFrom | Smart Account | True | True | 🧊 ColdAccess | 114765 | ERC721::transferFrom::Nexus::WithPaymaster::ColdAccess: 114765 |
|   ERC721 | transferFrom | Smart Account | False | False | 🔥 WarmAccess | 345947 | ERC721::transferFrom::Setup And Call::Using Pre-Funded Ether::WarmAccess: 345947 |
|   ERC721 | transferFrom | Smart Account | False | False | 🔥 WarmAccess | 297843 | ERC721::transferFrom::Setup And Call::UsingDeposit::WarmAccess: 297843 |
|   ERC721 | transferFrom | Smart Account | False | True | 🔥 WarmAccess | 314652 | ERC721::transferFrom::Setup And Call::WithPaymaster::WarmAccess: 314652 |
|   ERC721 | transferFrom | Smart Account | False | False | 🧊 ColdAccess | 365847 | ERC721::transferFrom::Setup And Call::Using Pre-Funded Ether::ColdAccess: 365847 |
|   ERC721 | transferFrom | Smart Account | False | False | 🧊 ColdAccess | 317743 | ERC721::transferFrom::Setup And Call::UsingDeposit::ColdAccess: 317743 |
|   ERC721 | transferFrom | Smart Account | False | True | 🧊 ColdAccess | 334552 | ERC721::transferFrom::Setup And Call::WithPaymaster::ColdAccess: 334552 |
|   ETH | call | EOA | False | False | 🔥 WarmAccess | 28201 | ETH::call::EOA::Simple::WarmAccess: 28201 |
|   ETH | send | EOA | False | False | 🔥 WarmAccess | 28201 | ETH::send::EOA::Simple::WarmAccess: 28201 |
|   ETH | transfer | EOA | False | False | 🔥 WarmAccess | 28073 | ETH::transfer::EOA::Simple::WarmAccess: 28073 |
|   ETH | call | EOA | False | False | 🧊 ColdAccess | 53201 | ETH::call::EOA::Simple::ColdAccess: 53201 |
|   ETH | send | EOA | False | False | 🧊 ColdAccess | 53201 | ETH::send::EOA::Simple::ColdAccess: 53201 |
|   ETH | transfer | EOA | False | False | 🧊 ColdAccess | 53073 | ETH::transfer::EOA::Simple::ColdAccess: 53073 |
|   ETH | transfer | Smart Account | True | False | 🔥 WarmAccess | 77604 | ETH::transfer::Nexus::Deployed::WarmAccess: 77604 |
|   ETH | transfer | Smart Account | True | True | 🔥 WarmAccess | 94089 | ETH::transfer::Nexus::WithPaymaster::WarmAccess: 94089 |
|   ETH | transfer | Smart Account | True | False | 🧊 ColdAccess | 102604 | ETH::transfer::Nexus::Deployed::ColdAccess: 102604 |
|   ETH | transfer | Smart Account | True | True | 🧊 ColdAccess | 119089 | ETH::transfer::Nexus::WithPaymaster::ColdAccess: 119089 |
|   ETH | transfer | Smart Account | False | False | 🔥 WarmAccess | 345181 | ETH::transfer::Setup And Call::Using Pre-Funded Ether::WarmAccess: 345181 |
|   ETH | transfer | Smart Account | False | False | 🔥 WarmAccess | 297076 | ETH::transfer::Setup And Call::UsingDeposit::WarmAccess: 297076 |
|   ETH | transfer | Smart Account | False | True | 🔥 WarmAccess | 313864 | ETH::transfer::Setup And Call::WithPaymaster::WarmAccess: 313864 |
|   ETH | transfer | Smart Account | False | False | 🧊 ColdAccess | 370181 | ETH::transfer::Setup And Call::Using Pre-Funded Ether::ColdAccess: 370181 |
|   ETH | transfer | Smart Account | False | False | 🧊 ColdAccess | 322076 | ETH::transfer::Setup And Call::UsingDeposit::ColdAccess: 322076 |
|   ETH | transfer | Smart Account | False | True | 🧊 ColdAccess | 338864 | ETH::transfer::Setup And Call::WithPaymaster::ColdAccess: 338864 |
|   UniswapV2 | swapExactETHForTokens | EOA | False | False | N/A | 149263 | UniswapV2::swapExactETHForTokens::EOA::ETHtoUSDC::N/A: 149263 |
|   UniswapV2 | swapExactTokensForTokens | EOA | False | False | N/A | 118252 | UniswapV2::swapExactTokensForTokens::EOA::WETHtoUSDC::N/A: 118252 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | True | False | N/A | 199230 | UniswapV2::swapExactETHForTokens::Nexus::Deployed::N/A: 199230 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | True | True | N/A | 215793 | UniswapV2::swapExactETHForTokens::Nexus::WithPaymaster::N/A: 215793 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | True | False | N/A | 200205 | UniswapV2::approve+swapExactTokensForTokens::Nexus::Deployed::N/A: 200205 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | True | False | N/A | 168209 | UniswapV2::swapExactTokensForTokens::Nexus::Deployed::N/A: 168209 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | True | True | N/A | 184784 | UniswapV2::swapExactTokensForTokens::Nexus::WithPaymaster::N/A: 184784 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | False | False | N/A | 418733 | UniswapV2::swapExactETHForTokens::Setup And Call::UsingDeposit::N/A: 418733 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | False | True | N/A | 435614 | UniswapV2::swapExactETHForTokens::Setup And Call::WithPaymaster::N/A: 435614 |
|   UniswapV2 | swapExactETHForTokens | Smart Account | False | False | N/A | 466838 | UniswapV2::swapExactETHForTokens::Setup And Call::Using Pre-Funded Ether::N/A: 466838 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | False | False | N/A | 419709 | UniswapV2::approve+swapExactTokensForTokens::Setup And Call::UsingDeposit::N/A: 419709 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | False | True | N/A | 436780 | UniswapV2::approve+swapExactTokensForTokens::Setup And Call::WithPaymaster::N/A: 436780 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | False | False | N/A | 387700 | UniswapV2::swapExactTokensForTokens::Setup And Call::UsingDeposit::N/A: 387700 |
|   UniswapV2 | swapExactTokensForTokens | Smart Account | False | True | N/A | 404582 | UniswapV2::swapExactTokensForTokens::Setup And Call::WithPaymaster::N/A: 404582 |
|   UniswapV2 | approve+swapExactTokensForTokens | Smart Account | False | False | N/A | 467815 | UniswapV2::approve+swapExactTokensForTokens::Setup And Call::Using Pre-Funded Ether::N/A: 467815 |
