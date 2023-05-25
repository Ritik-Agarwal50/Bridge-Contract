pragma solidity ^0.8.10;

interface IToken {
    function mint(address to, uint amount) external;

    function burn(address owner, uint amount) external;
}
