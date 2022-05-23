# Simple script for installing validator and network nodes.
Quick and simple setup node for Klin network #ETH2

### Requirements
`
sudo apt install git  build-essential
`


# Setup
## 1. Step permissions
`chown +x klin_node.sh`

## 2. Step install requirements and compile 
`./klin_node.sh setup`

## 3. run lodestar
`./klin_node.sh cl_client`

## 4. run  client
`./klin_node.sh start_el_client`

## 5. run  validator
`./klin_node.sh validator`
