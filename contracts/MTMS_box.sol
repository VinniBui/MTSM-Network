// SPDX-License-Identifier: UNLICENSED
//TODO: Change above comment !
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MTMSBox is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public MTMSImage;
  string public baseExtension = ".json"; //Can be changed later
  uint256 public cost = 1 ether; //TODO: Change this value before deploy!
  uint256 public maxSupply = 300000;  //TODO: Change this value before deploy! Caution: this value CAN NOT be cahnged after deployed!
  bool public paused = false;
  bool public revealed = false;
  string public epicBoxUri;
  string public commonBoxUri;
  mapping(address => bool) public whitelisted;
  string[] public nftTypeName = ["silver","gold","platinum"];
  string[] public nftDefaultURI = ["","",""]; 

  struct tokenInfor {
    uint256 id;
    bool isBoxOpenned;
    bool isEpicBox;
    string nftType;
    string nftURI;
  }

  mapping (uint256 => tokenInfor) public tokenInfors;
  //Silver, Gold, Platinum for commonBox
  uint public numberSilverNftOfCommonBox = 0;
  uint public numberGoldNftOfCommonBox = 0; 
  uint public numberPlatinumNftOfCommonBox = 0;

  //Silver, Gold, Platinum for epicBox
  uint public numberSilverNftOfEpicBox = 0;
  uint public numberGoldNftOfEpicBox = 0; 
  uint public numberPlatinumNftOfEpicBox = 0;

  constructor(
  ) ERC721("MTMSNFT", "MTMS") {
  }
  
  function baseTokenURI() public view returns (string memory) {
    return MTMSImage;
  }

  function mint(bool _isEpicBox, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(supply +_mintAmount <= maxSupply);
    
    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      tokenInfors[supply + i].id = supply + i;
      tokenInfors[supply + i].isBoxOpenned = false;
      tokenInfors[supply + i].nftType = "Box";
      tokenInfors[supply + i].isEpicBox = _isEpicBox;
      tokenInfors[supply + i].nftURI = "";
      _safeMint(msg.sender , supply + i);
    }
      
  }

//   function walletOfOwner(address _owner)
//     public
//     view
//     returns (uint256[] memory)
//   {
//     uint256 ownerTokenCount = balanceOf(_owner);
//     uint256[] memory tokenIds = new uint256[](ownerTokenCount);
//     for (uint256 i; i < ownerTokenCount; i++) {
//       tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
//     }
//     return tokenIds;
//   }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    return getURI(tokenId);
    // if(tokenInfors[tokenId].isBoxOpenned == false) {
    //     if (tokenInfors[tokenId].isEpicBox == false) {
    //       return commonBoxUri;
    //     } 
    //     return epicBoxUri;
    // }

    // string memory currentBaseURI = _baseURI();
    // return bytes(currentBaseURI).length > 0
    //     ? string(abi.encodePacked(currentBaseURI, tokenInfors[tokenId].nftType, baseExtension))  // fix me
    //     : "";
  }

  function openBox(uint256 tokenId)
    public
    returns (string memory) {
        require(ownerOf(tokenId) == msg.sender,
        "Only owner of token can unbox!"
        );
         require(revealed,
        "Smart contract have not revealed!"
        );
        require(!tokenInfors[tokenId].isBoxOpenned,
        "This box has already been unboxed");
        uint256 numberSilverNft = numberSilverNftOfCommonBox;
        uint256 numberGoldNft = numberGoldNftOfCommonBox;
        uint256 numberPlatinumNft = numberPlatinumNftOfCommonBox;

        if (tokenInfors[tokenId].isEpicBox) {
          numberSilverNft = numberSilverNftOfEpicBox;
          numberGoldNft = numberGoldNftOfEpicBox;
          numberPlatinumNft = numberPlatinumNftOfEpicBox;
        }

        uint256 totalNft = numberSilverNft+numberGoldNft+numberPlatinumNft;

        require(totalNft > 0, 
        "There is no NFT left! You can not open box this time!");

        uint256 randNum = randomNum(totalNft,block.timestamp,totalSupply()) + 1;
        tokenInfors[tokenId].isBoxOpenned = true;
        if (randNum <= numberSilverNft) {
          if (!tokenInfors[tokenId].isEpicBox) {
            numberSilverNftOfCommonBox = numberSilverNftOfCommonBox -1;
          } else {
            numberSilverNftOfEpicBox = numberSilverNftOfEpicBox - 1;
          }
          tokenInfors[tokenId].nftType = nftTypeName[0];
          return getURI(tokenId); 
        }
        if (randNum <= numberSilverNft+numberGoldNft) {
          if (!tokenInfors[tokenId].isEpicBox) {
            numberGoldNftOfCommonBox = numberGoldNftOfCommonBox -1;
          } else {
            numberGoldNftOfEpicBox = numberGoldNftOfEpicBox - 1;
          }
          tokenInfors[tokenId].nftType = nftTypeName[1];
          return getURI(tokenId);
        }
         if (!tokenInfors[tokenId].isEpicBox) {
            numberPlatinumNftOfCommonBox = numberPlatinumNftOfCommonBox -1;
          } else {
            numberPlatinumNftOfEpicBox = numberPlatinumNftOfEpicBox - 1;
          }
        tokenInfors[tokenId].nftType = nftTypeName[2];
        return getURI(tokenId);
    }

  function randomNum(uint256 _mod, uint256 _seed, uint256 _salt) private view returns(uint256) {
    uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,_seed,_salt))) % _mod;
    return num;
  }

  function getURI(uint256 tokenId) internal view returns(string memory) {
    if (tokenInfors[tokenId].isBoxOpenned == false) {
      if (tokenInfors[tokenId].isEpicBox == false) {
          return commonBoxUri;
        } 
        return epicBoxUri;
    }
    if (bytes(tokenInfors[tokenId].nftURI).length != 0) {
      return tokenInfors[tokenId].nftURI;
    }

    if (keccak256(bytes(tokenInfors[tokenId].nftType)) == keccak256(bytes("silver"))) { 
      if (bytes(nftDefaultURI[0]).length != 0) {
        return nftDefaultURI[0];
      }
      return string(abi.encodePacked(_baseURI(), tokenInfors[tokenId].nftType, baseExtension));  
    }

    if (keccak256(bytes(tokenInfors[tokenId].nftType)) == keccak256(bytes("gold"))) { 
      if (bytes(nftDefaultURI[1]).length != 0) {
        return nftDefaultURI[1];
      }
      return string(abi.encodePacked(_baseURI(), tokenInfors[tokenId].nftType, baseExtension));  
    }

    if (bytes(nftDefaultURI[2]).length != 0) {
        return nftDefaultURI[2];
      }
    return string(abi.encodePacked(_baseURI(), tokenInfors[tokenId].nftType, baseExtension));  
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function getTokenIds(address _owner) public view returns (tokenInfor[] memory) {
        tokenInfor[] memory _tokensOfOwner = new tokenInfor[](balanceOf(_owner));
        uint256 i;

        for (i=0;i<balanceOf(_owner);i++){
          uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            _tokensOfOwner[i] = tokenInfors[tokenId];
        }
        return (_tokensOfOwner);
  }
  //below functions are only owner functions! 
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setMTMSImage(string memory _newMTMSImage) public onlyOwner {
    MTMSImage = _newMTMSImage;
  }

   function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setNumberNftOfCommonBox(uint256  _numberSilverNft,uint256  _numberGoldNft,uint256 _numberPlatinumNft) public onlyOwner {
    numberSilverNftOfCommonBox = _numberSilverNft;
    numberGoldNftOfCommonBox = _numberGoldNft;
    numberPlatinumNftOfCommonBox = _numberPlatinumNft;
  } 

  function setNumberNftOfEpicBox(uint256  _numberSilverNft,uint256  _numberGoldNft,uint256 _numberPlatinumNft) public onlyOwner {
    numberSilverNftOfEpicBox = _numberSilverNft;
    numberGoldNftOfEpicBox = _numberGoldNft;
    numberPlatinumNftOfEpicBox = _numberPlatinumNft;
  } 
  
  function setMetadataByTokenId(string memory _metadataURI,uint256 _tokenId) public onlyOwner {
    tokenInfors[_tokenId].nftURI = _metadataURI;
  }

  function setEpicBoxURI(string memory _epicBoxURI) public onlyOwner {
    epicBoxUri = _epicBoxURI;
  }

  function setCommonBoxURI(string memory _commonBoxURI) public onlyOwner {
    commonBoxUri = _commonBoxURI;
  }

  function setSilverNFTURI(string memory _silverNftURI) public onlyOwner {
    nftDefaultURI[0] = _silverNftURI; 
  }

  function setGoldNFTURI(string memory _goldNftURI) public onlyOwner {
    nftDefaultURI[1] = _goldNftURI;
  }

  function setPlatinumNFTURI(string memory _platinumNftURI) public onlyOwner {
    nftDefaultURI[2] = _platinumNftURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}