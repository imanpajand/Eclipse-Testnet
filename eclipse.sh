prompt() {
    read -p "$1" response
    echo $response
}

execute_and_prompt() {
    echo -e "\n$1"
    eval "$2"
    read -p "Press [Enter] to continue..."
}

cd $HOME

execute_and_prompt "Installing Prerequisites..." "sudo apt update && sudo apt upgrade -y"

if ! command -v rustc &> /dev/null; then
    response=$(prompt "Do you want to install Rust? (Reply 1 to proceed) ")
    if [ "$response" == "1" ]; then
        execute_and_prompt "Installing Rust..." "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        source "$HOME/.cargo/env"
        execute_and_prompt "Checking Rust Version..." "rustc --version"
    fi
else
    echo "Rust is already installed. Skipping installation."
fi

execute_and_prompt "Removing Existing Node.js Installation..." "sudo apt-get remove nodejs"

response=$(prompt "Do you want to proceed with removing Node.js? (Reply 'y' to proceed) ")
if [ "$response" == "y" ]; then
    sudo apt-get remove nodejs
fi

execute_and_prompt "Installing NVM and Updating Node.js..." 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && export NVM_DIR="/usr/local/share/nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"; source ~/.bashrc; nvm install --lts; nvm use --lts; node -v'
execute_and_prompt "Cloning Eclipse Bridge Script..." "git clone https://github.com/Eclipse-Laboratories-Inc/testnet-deposit && cd testnet-deposit && npm install"

if ! command -v solana &> /dev/null; then
    execute_and_prompt "Installing Solana CLI..." 'sh -c "$(curl -sSfL https://release.solana.com/stable/install)"'
    
    export PATH="/home/codespace/.local/share/solana/install/active_release/bin:$PATH"
    
    execute_and_prompt "Checking Solana Version..." "solana --version"
else
    echo "Solana CLI is already installed. Skipping installation."
fi

execute_and_prompt "Creating Solana Wallet..." "solana-keygen new -o ~/my-wallet.json"
execute_and_prompt "Updating Solana Configuration..." "solana config set --url https://testnet.dev2.eclipsenetwork.xyz/ && solana config set --keypair ~/my-wallet.json"
execute_and_prompt "Checking Solana Address..." "solana address"

echo -e "\nImport your BIP39 Passphrase to OKX Wallet to get EVM Address. Claim Faucet with your Main Address and Send Sepolia ETH to this new address"
echo -e "\nSepolia Faucet Links:\nhttps://faucet.quicknode.com/ethereum/sepolia\nhttps://faucets.chain.link/\nhttps://www.infura.io/faucet"
read -p "Press [Enter] to continue..."

if [ -d "testnet-deposit" ]; then
    execute_and_prompt "Removing testnet-deposit Folder..." "rm -rf testnet-deposit"
fi

solana_address=$(prompt "Enter your Solana Address: ")
ethereum_private_key=$(prompt "Enter your Ethereum Private Key: ")
repeat_count=$(prompt "Enter The Number Of Times To Repeat The Transaction (Recommended 4-5): ")

gas_limit="3000000"
gas_price="100000"

for ((i=1; i<=repeat_count; i++)); do
    execute_and_prompt "Running Bridge Script (Tx $i)..." "node deposit.js $solana_address 0x7C9e161ebe55000a3220F972058Fb83273653a6e $gas_limit $gas_price ${ethereum_private_key:2} https://rpc.sepolia.org"
done

execute_and_prompt "Checking Solana Balance..." "solana balance"

balance=$(solana balance | awk '{print $1}')
if [ "$balance" == "0" ]; then
    echo "Your Solana Balance Is 0. Please Deposit Funds And Try Again"
    exit 1
fi

execute_and_prompt "Creating Token..." "spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"

token_address=$(prompt "Enter Your Token Address: ")
execute_and_prompt "Creating Token Account..." "spl-token create-account $token_address"

execute_and_prompt "Minting Token..." "spl-token mint $token_address 10000"
execute_and_prompt "Checking Token Accounts..." "spl-token accounts"

execute_and_prompt "Checking Program Address..." "solana address"
echo -e "\nSubmit Feedback at: https://docs.google.com/forms/d/e/1FAIpQLSfJQCFBKHpiy2HVw9lTjCj7k0BqNKnP6G1cd0YdKhaPLWD-AA/viewform?pli=1"
