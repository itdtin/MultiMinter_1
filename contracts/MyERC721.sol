// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public salePrice = 0.001 ether;

    constructor() ERC721("MyERC721", "MERC") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://huilo.huilo.ru/images";
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function purchase(uint256 quantity) external payable returns (uint256){
        require(msg.value >= salePrice * quantity, "HUI tebe a ne MINT");
        require(quantity == 1, "SLISHKOM MNOGO NFT XOCHESH");
        safeMint(_msgSender());
        uint256 firstMintedTokenId = _tokenIdCounter.current() - quantity;
        return firstMintedTokenId;
    }
}