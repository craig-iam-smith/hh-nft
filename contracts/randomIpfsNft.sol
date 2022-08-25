// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "hardhat/console.sol";

error AlreadyInitialized();
error NeedMoreETHSent();
error RangeOutOfBounds();
error RandomIpfsNft__TransferFailed();
   
contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
// when minting an NFT, we will trigger a Chainlink VRF call to get a random number
// produce a random NFT
// pug, shiba inu, St. Bernard
    enum Breed {
        PUG,
        SHIBA_INU,
        ST_BERNARD
        
    }
    // VRF Helpers
    mapping(uint256 => address) s_requestIdToSender;

    // NFT variables
    uint256 s_tokenCounter;
    uint256 constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    bool private s_initialized;
    uint256 private immutable i_mintFee;

    // Events
    event NftRequested(uint256 indexed requestId, address minter);
    event NftMinted(Breed dogBreed, address minter);

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    
    constructor(address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[3] memory dogTokenUris
        ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721 ("Random IPFS NFT", "RIN") {
            i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
            i_subscriptionId = subscriptionId;
            i_mintFee = mintFee;
            i_gasLane = gasLane;
            i_callbackGasLimit = callbackGasLimit;
            _initializeContract(dogTokenUris);
        }
        // vrfCoordinatorV2, 
    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert NeedMoreETHSent();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);

    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;
        
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Breed dogBreed = getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner, newTokenId);
        _setTokenURI(newTokenId, s_dogTokenUris[uint256(dogBreed)]);
        emit NftMinted(dogBreed, dogOwner);


    }

    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed) {
        uint256[3] memory chanceArray = getChanceArray();
        uint256 i=chanceArray.length-1;
        uint256 breed=i;
        while (i-- >= 0) {
            if (moddedRng < chanceArray[i])
                breed=i;
        }
        return Breed(breed);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }

    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10,30, MAX_CHANCE_VALUE];
    }

    function _initializeContract(string[3] memory dogTokenUris) private {
        if (s_initialized) {
            revert AlreadyInitialized();
        }
        s_dogTokenUris = dogTokenUris;
        s_initialized = true;
    }


    function getDogTokenUris(uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    function getMintFee() public view returns(uint256){
        return i_mintFee;
    }

//    function getDogTokenUris(uint256 index) public view returns (string memory) {
//        return s_dogTokenUris[index];
//    }

    function getTokenCounter() public view returns(uint256) {
        return s_tokenCounter;
    }
}