#!/bin/bash
# Klin validor #ETH2

set -e

ETH_ROOT_DIR=$HOME/eth
ETH_WITHDRAW_ADDRESS=${1:-false}
RUN_SETUP=${2:-false}
EL_DATA_DIR=$ETH_ROOT_DIR/el-data
CL_DATA_DIR=$ETH_ROOT_DIR/cl-data
CONFIG_DIR=$ETH_ROOT_DIR/merge-testnets/kiln
JWT_SECRET_PATH=$ETH_ROOT_DIR/jwtsecret
VALIDATOR_KEYS_DIR=$ETH_ROOT_DIR/validator_keys

function run_in_new_terminal() {
        eval "$1"
}

function start_el_client() {
        mkdir -p $EL_DATA_DIR
        run_in_new_terminal "cd $ETH_ROOT_DIR/ethereumjs-monorepo/packages/client && \
npm run client:start -- --datadir $EL_DATA_DIR \
--gethGenesis $CONFIG_DIR/genesis.json --saveReceipts --rpc --rpcport=8545 \
--ws --rpcEngine --rpcEnginePort=8551 --bootnodes=165.232.180.230:30303 --jwt-secret=$JWT_SECRET_PATH" 
}

function start_cl_client() {
        mkdir -p $CL_DATA_DIR
        run_in_new_terminal "cd $ETH_ROOT_DIR/lodestar && ./lodestar beacon \
--rootDir=$CL_DATA_DIR --paramsFile=$CONFIG_DIR/config.yaml \
--genesisStateFile=$CONFIG_DIR/genesis.ssz --eth1.enabled=true \
--execution.urls=http://127.0.0.1:8551 --network.connectToDiscv5Bootnodes --network.discv5.enabled=true \
--eth1.depositContractDeployBlock=0 \
--jwt-secret=$JWT_SECRET_PATH --network.discv5.bootEnrs=enr:-Iq4QMCTfIMXnow27baRUb35Q8iiFHSIDBJh6hQM5Axohhf4b6Kr_cOCu0htQ5WvVqKvFgY28893DHAg8gnBAXsAVqmGAX53x8JggmlkgnY0gmlwhLKAlv6Jc2VjcDI1NmsxoQK6S-Cii_KmfFdUJL2TANL3ksaKUnNXvTCv1tLwXs0QgIN1ZHCCIyk"
}

function start_val_client() {
        echo "Starting validator client..."
        run_in_new_terminal "cd $ETH_ROOT_DIR/lodestar && ./lodestar validator --paramsFile=$CONFIG_DIR/config.yaml"
}

function initial_setup() {

	     curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 

       source .profile
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion 

        # Node.js & Yarn
        nvm install --lts
        corepack enable

        # Set up directories
        mkdir -p $ETH_ROOT_DIR

        # Download kiln config
        cd $ETH_ROOT_DIR
        if [ ! -d "merge-testnets" ] ; then
        git clone https://github.com/eth-clients/merge-testnets.git
        fi

        # Generate JWT secret
       openssl rand -hex 32 | tr -d "\n" > "$JWT_SECRET_PATH"

        # Set up EL client - EthereumJS
        cd $ETH_ROOT_DIR

        if [ ! -d "ethereumjs-monorepo" ] ; then
         git clone --depth 1 --branch master https://github.com/ethereumjs/ethereumjs-monorepo.git
        fi
        cd ethereumjs-monorepo
       npm i

        # Start CL client - Lodestar
       cd $ETH_ROOT_DIR

        if [ ! -d "lodestar" ] ; then
          git clone https://github.com/chainsafe/lodestar.git
        fi

        cd $ETH_ROOT_DIR/lodestar
       yarn install --ignore-optional
       yarn run build

        # Generate validator keys
        if [[ "$RUN_VALIDATOR" == "true" ]]; then
                cd $ETH_ROOT_DIR
                curl -LO https://github.com/ethereum/staking-deposit-cli/releases/download/v2.1.0/staking_deposit-cli-ce8cbb6-linux-amd64.tar.gz
                tar -xzf staking_deposit-cli-ce8cbb6-linux-amd64.tar.gz --strip-components=2

                mkdir -p $VALIDATOR_KEYS_DIR
                ./deposit --language English new-mnemonic --num_validators "1" --mnemonic_language=English \
                        --chain kiln --folder "$VALIDATOR_KEYS_DIR" --eth1_withdrawal_address "$ETH_WITHDRAW_ADDRESS"
                echo "Successfully generated validator keys at $VALIDATOR_KEYS_DIR. Upload the deposit_data json file to Kiln Launchpad here: https://kiln.launchpad.ethereum.org/en/"

                # Importing keys - password required
                cd $ETH_ROOT_DIR/lodestar
                ./lodestar account validator import --paramsFile=$CONFIG_DIR/config.yaml \
                        --directory $VALIDATOR_KEYS_DIR
        fi
        
}

if [[ "$RUN_SETUP" == "setup" ]]; then
        initial_setup
fi

if [[ "$RUN_SETUP" == "el_client" ]]; then
        start_el_client
fi

if [[ "$RUN_SETUP" == "cl_client" ]]; then
        start_cl_client
fi

if [[ "$RUN_SETUP" == "validator" ]]; then
         start_val_client
fi


