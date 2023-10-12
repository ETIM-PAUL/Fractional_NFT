// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FractionToken is ERC20, ERC20Burnable {
    address public NFTAddress;
    uint256 public NFTId;
    address public NFTOwner;

    address public ContractDeployer;
    uint256 public constant ROYALTY_PERCENTAGE = 1000;

    address[] tokenOwners;
    uint public totalSupplyT;
    mapping(address => bool) isHolding;

    constructor(
        address _NFTAddress,
        uint256 _NFTId,
        address _NFTOwner,
        string memory _tokenName,
        string memory _tokenTicker
    ) ERC20(_tokenName, _tokenTicker) {
        NFTAddress = _NFTAddress;
        NFTId = _NFTId;
        NFTOwner = _NFTOwner;
        ContractDeployer = msg.sender;
    }

    function mint(address purchaser, uint amount) public {
        _mint(purchaser, amount);
        totalSupplyT++;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        //calculate royalty fee
        address owner = _msgSender();

        _transfer(owner, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return true;
    }

    function burn(uint256 amount) public virtual override {
        _burn(_msgSender(), amount);
    }

    function updateNFTOwner(address _newOwner) public {
        require(
            msg.sender == ContractDeployer,
            "Only contract deployer can call this function"
        );

        NFTOwner = _newOwner;
    }

    function returnTokenOwners() public view returns (address[] memory) {
        return tokenOwners;
    }
}
