{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet mainnet) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet sepolia) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet base) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet base-sepolia) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet polygon) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet amoy) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet arbitrum) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet arbitrum-sepolia) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet optimism) } # || { (printf "====== ALERT ======\nBSC :: probably errors => check logs\n====== ALERT ======\n") }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet optimism-sepolia) } 
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet bsc) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet bsc-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet sonic-mainnet) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet sonic-blaze-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet scroll) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet scroll-sepolia) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet gnosis) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet gnosis-chiado) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet avalanche) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet fuji) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet apechain) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet apechain-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet hyperevm) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet coredao-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet neura-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet sei-mainnet) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet sei-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet unichain-mainnet) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet unichain-testnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet katana-mainnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet lisk-mainnet) }
{ (printf '==========================\n') }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet worldchain-mainnet) }
{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet worldchain-testnet) }