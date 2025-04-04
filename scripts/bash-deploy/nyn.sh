# TESTNETS

#printf '%s\n' n y n | bash deploy-nexus.sh testnet bsc-testnet
#printf '%s\n' n y n | bash deploy-nexus.sh testnet optimism-sepolia
#printf '%s\n' n y n | bash deploy-nexus.sh testnet arbitrum-sepolia
#printf '%s\n' n y n | bash deploy-nexus.sh testnet amoy
#printf '%s\n' n y n | bash deploy-nexus.sh testnet base-sepolia 
#printf '%s\n' n y n | bash deploy-nexus.sh testnet sepolia

#{ (printf '%s\n' n y n | bash deploy-nexus.sh testnet gnosis-chiado) } || { (printf "Gnosis chiado :: probably errors => check logs\n") }

# MAINNETS
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet bsc) } || { (printf "====== ALERT ======\nBSC :: probably errors => check logs\n====== ALERT ======\n") }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet optimism) } || { (printf "====== ALERT ======\nOptimism :: probably errors => check logs\n====== ALERT ======\n") }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet arbitrum) } || { (printf "====== ALERT ======\nArbitrum :: probably errors => check logs\n====== ALERT ======\n") }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet polygon) } || { (printf "====== ALERT ======\nPolygon :: probably errors => check logs\n====== ALERT ======\n") }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet base) } || { (printf "====== ALERT ======\nBase :: probably errors => check logs\n====== ALERT ======\n") }
{ (printf '%s\n' n y n | bash deploy-nexus.sh mainnet mainnet) } || { (printf "====== ALERT ======\nMainnet :: probably errors => check logs\n====== ALERT ======\n") }