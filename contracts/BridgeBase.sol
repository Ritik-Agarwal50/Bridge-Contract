//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeBase{
    address public admin;
    IToken public token;
    mapping(address => mapping(uint => bool)) public processedNonces;
    enum Step {burn,mint};
    event transfer(
        address from,
        address to,
        uint amount,
        uint date,
        uint nonce,
        bytes signature,
        Step indexed step
    );

    constructor(address _token){
        admin = msg.sender;
        token = IToken(_token);
    }

    function recoverSigner(bytes32 message,bytes memory sig) internal pure returns(address){
        uint8 y,
        bytes32 r,
        bytes32 s;

        (v,r,s) = splitSignature(sig);

        return ecrecover(message,v,r,s);
    }

    function splitSignature(bytes memory sig) internal pure returns(uint8,bytes32,bytes32){
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig,32))
            s := mload(add(sig,64))

            v:= byte(0,mload(Add(sig,96)))
        }

        return (v,r,s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

    function mint(address from,address to,uint amount,uint nonce,bytes calldata signature) external{
        bytes32 message = prefixed(keccak256(abi.encodePacked(from,to,amount,nonce)));
        require(recoverSigner(message,signature) == from ,"Wrong signature");
        require(processedNonces[from][nonce] == false, "transfer already done");
        processedNonces[from][nonce] = true;
        token.mint(to,amount);
        emit transfer(from,to,amount,block.timestamp,nonce,signature,Step.mint);
    }

}