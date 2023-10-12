// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "./interface/IERC721.sol";
import "./FractionTokens.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MarketPlace {
    event NFTSold(uint256 indexed orderId, DepositInfo);

    event NFTListed(uint256 indexed orderId, DepositInfo);

    event NFTOrderEdited(uint indexed orderId, DepositInfo);

    struct DepositInfo {
        address owner;
        address nftContractAddress;
        uint256 nftId;
        uint256 depositTimestamp; //deposited time
        //post fractionalize info
        address fractionContractAddress;
        uint256 supply;
        uint totalGain;
        uint nftFractionPrice;
        bool hasFractionalized; //has deposited nft been fractionalizeds
    }

    mapping(address => DepositFolder) AccessDeposits;
    mapping(address => mapping(uint256 => uint256)) NftIndex;

    //storage folder that can be expanded to hold more structs and then be accessed by a mapping (nftDeposits)
    struct DepositFolder {
        DepositInfo[] Deposit;
    }

    uint orderId;

    constructor() {}

    function depositNft(
        address _nftContractAddress,
        uint256 _nftId
    ) public returns (bool success) {
        //address must approve this contract to transfer the nft they own before calling this function
        //fractionalize contract needs to hold the nft so it can be fractionalize
        ERC721 NFT = ERC721(_nftContractAddress);
        NFT.transferFrom(msg.sender, address(this), _nftId);

        DepositInfo memory newDeposit;

        newDeposit.owner = msg.sender;
        newDeposit.nftContractAddress = _nftContractAddress;
        newDeposit.nftId = _nftId;
        newDeposit.depositTimestamp = block.timestamp;

        newDeposit.hasFractionalized = false;

        //set index location of nft in nft folder to prevent the need of for loops when accessing deposit information
        NftIndex[_nftContractAddress][_nftId] = AccessDeposits[msg.sender]
            .Deposit
            .length;

        //save the new infomation into the smart contract
        AccessDeposits[msg.sender].Deposit.push(newDeposit);
        success = true;
    }

    function createFraction(
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _supply,
        uint _nftFractionPrice,
        string memory _tokenName,
        string memory _tokenTicker
    ) public returns (bool success) {
        uint256 index = NftIndex[_nftContractAddress][_nftId];
        require(
            AccessDeposits[msg.sender].Deposit[index].owner == msg.sender,
            "Only the owner of this NFT can access it"
        );

        AccessDeposits[msg.sender].Deposit[index].hasFractionalized = true;
        AccessDeposits[msg.sender].Deposit[index].supply = _supply;
        AccessDeposits[msg.sender]
            .Deposit[index]
            .nftFractionPrice = _nftFractionPrice;

        FractionToken fractionToken = new FractionToken(
            _nftContractAddress,
            _nftId,
            msg.sender,
            _tokenName,
            _tokenTicker
        );

        AccessDeposits[msg.sender]
            .Deposit[index]
            .fractionContractAddress = address(fractionToken);
        success = true;
    }

    function purchaseOneFraction(
        address _fractionContract,
        address _nftContractAddress,
        uint256 _nftId
    ) public payable {
        FractionToken fraction = FractionToken(_fractionContract);
        uint256 index = NftIndex[_nftContractAddress][_nftId];

        uint nftFractionPrice = AccessDeposits[msg.sender]
            .Deposit[index]
            .nftFractionPrice;
        require(msg.value == nftFractionPrice, "Incorrect Eth Price");
        require(
            AccessDeposits[msg.sender].Deposit[index].supply <
                fraction.totalSupplyT(),
            "Supply Reached"
        );
        fraction.mint(msg.sender, 1);

        AccessDeposits[msg.sender].Deposit[index].totalGain += msg.value;
    }

    //can withdraw the NFT if you own the total supply
    function withdrawGainsAndTransferNFT(address _fractionContract) public {
        //address must approve this contract to transfer fraction tokens

        FractionToken fraction = FractionToken(_fractionContract);
        uint256 index = NftIndex[fraction.NFTAddress()][fraction.NFTId()];

        address NFTAddress = fraction.NFTAddress();
        address NFTOwner = fraction.NFTOwner();
        uint256 NFTId = fraction.NFTId();

        uint256 totalGainFromFractions = AccessDeposits[NFTOwner]
            .Deposit[index]
            .totalGain;
        address nftOwner = AccessDeposits[NFTOwner].Deposit[index].owner;

        require(
            fraction.ContractDeployer() == address(this),
            "Only fraction tokens created by this fractionalize contract can be accepted"
        );
        require(
            fraction.balanceOf(msg.sender) == fraction.totalSupplyT(),
            "Total Supply Not reached"
        );

        //remove tokens from existence as they are no longer valid (NFT leaving this contract)
        fraction.transferFrom(
            msg.sender,
            address(this),
            fraction.totalSupply()
        );
        fraction.burn(fraction.totalSupply());

        delete AccessDeposits[NFTOwner].Deposit[index];

        //calculate royalty fee
        uint256 royaltyFee = (totalGainFromFractions *
            fraction.ROYALTY_PERCENTAGE()) / 100;
        uint afterRoyaltyFee = totalGainFromFractions - royaltyFee;

        (bool sent, bytes memory data) = payable(nftOwner).call{
            value: afterRoyaltyFee
        }("");
        require(sent, "Failed to send Ether");

        ERC721 NFT = ERC721(NFTAddress);
        NFT.transferFrom(address(this), msg.sender, NFTId);
    }

    function transferNFTFractions(
        address _fractionContract,
        address _to
    ) public returns (bool success) {
        //address must approve this contract to transfer fraction tokens

        FractionToken fraction = FractionToken(_fractionContract);
        uint256 index = NftIndex[fraction.NFTAddress()][fraction.NFTId()];

        require(amount > 0, "Zero Amount Not Allowed");
        require(fraction.balanceOf(msg.sender) <= amount, "Amount Higher");

        fraction.transferFrom(msg.sender, _to, amount);
        success = true;
    }

    function withdrawNftNotFractionalized(
        address _NftContract,
        uint _NftId
    ) public {
        uint256 index = NftIndex[_NftContract][_NftId];
        require(
            AccessDeposits[msg.sender].Deposit[index].hasFractionalized ==
                false,
            "Only if the NFT hasn't been fractionalise can you withdraw the NFT with this function"
        );
        require(
            AccessDeposits[msg.sender].Deposit[index].owner == msg.sender,
            "Only the NFT owner can call this function"
        );

        ERC721 NFT = ERC721(_NftContract);
        NFT.safeTransferFrom(address(this), msg.sender, _NftId);

        delete AccessDeposits[msg.sender].Deposit[index];
    }

    //receive function
    fallback() external payable {}

    // function onERC721Received(
    //     address,
    //     address from,
    //     uint256,
    //     bytes calldata
    // ) external pure override returns (bytes4) {
    //     return IERC721Receiver.onERC721Received.selector;
    // }
}
