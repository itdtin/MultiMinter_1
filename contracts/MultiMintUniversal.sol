// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface NFT {
    // function mint(uint256 _amount) external payable;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // function NFT_PRICE() external view returns (uint256);

    // function MAX_SUPPLY() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // function mintStartTime() external view returns (uint256);

    function ownerOf(uint256 tokenID) external view returns (address);

    function balanceOf(address proxy) external view returns (uint256);
}

interface ERC1155 {
  function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

struct WithdrawData {
    address payable cloneAddress;
    uint256[] tokenIds;
}

struct WithdrawData1155 {
    address payable cloneAddress;
    uint256 tokenId;
    uint256 amount;
}

contract MultiMinter is Ownable {
    address payable[] public clones;
    address public saleAddress;

    uint256 public nftPrice;
    uint256 public maxSupply;
    uint256 public tokensForWallet;

    bool initialized;
    address public _owner;

    constructor(
        address _saleAddress,
        uint256 _nftPrice,
        uint256 _maxSupply
    ) {
        saleAddress = _saleAddress;
        _owner = msg.sender;
        nftPrice = _nftPrice;
        maxSupply = _maxSupply;
    }

    function setDropInfo(
        uint256 _nftprice,
        address saleaddr,
        uint256 _maxSupply
    ) public onlyOwner {
        saleAddress = saleaddr;
        maxSupply = _maxSupply;
        nftPrice = _nftprice;
    }

    modifier validateTx(uint256 _txCount, uint256 _numberOfTokens) {
        uint256 totalMint = _numberOfTokens * _txCount;
        require(
            NFT(saleAddress).totalSupply() + totalMint <= maxSupply,
            "Minter: low supply"
        );
        require(msg.value == nftPrice * totalMint, "Minter: wrong value");
        _;
    }

    modifier _validateTx(uint256 clonesQuantity, uint256 mintPerClone) {
        uint256 totalMint = mintPerClone * clonesQuantity;
        require(
            NFT(saleAddress).totalSupply() + totalMint <= maxSupply,
            "Minter: low supply"
        );
        _;
    }

    function newClone() internal returns (address payable result) {
        bytes20 targetBytes = bytes20(address(this));

        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }

        return result;
    }

    function setOwner(address owner) external {
        require(!initialized, "already set");
        _owner = owner;
        initialized = true;
    }

    function deployClones(uint256 quantity) public {
        for (uint256 i; i < quantity; i++) {
            address payable clone = newClone();
            clones.push(clone);
            // clone.transfer(nftPrice);
            MultiMinter(clone).setOwner(address(this));
        }
    }

    function fundClones(uint256 amount, uint256 nftNumberPerClone)
        public
        payable
    {
        require(
            clones.length * nftPrice * nftNumberPerClone <= msg.value,
            "Not enough Ether"
        );
        require(clones.length >= amount, "Not enough clones");
        for (uint256 i; i < amount; i++) {
            clones[i].transfer(nftPrice * nftNumberPerClone);
        }
    }

    function withdrawEth(address payable owner) public {
        require(msg.sender == _owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    function withdrawEthClones(address payable owner) public onlyOwner {
        for (uint256 i; i < clones.length; i++) {
            MultiMinter(clones[i]).withdrawEth(owner);
        }
    }

    function mintFromDeployedClones(
        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall
    ) public onlyOwner {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();
        uint256 lastClone;
        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
            lastClone = remaining % (mintPerCall * txPerClone);
        }
        for (uint256 i; i < clonesAmount; i++) {
            for (uint256 j; j < txPerClone; j++){
                (bool success, bytes memory result) = clones[i].call(
                    abi.encodeWithSignature(
                        "mintClone(address,uint8,uint256,bytes)",
                        saleAddress,
                        mintPerCall,
                        nftPrice,
                        datacall
                    )
                );
                if (!success) return;
                bool res = abi.decode(result, (bool));
                if (!res) return;
            }
        }
        if (lastClone > 0) {
            if (lastClone / mintPerCall > 0)
                for (uint256 j; j < lastClone / mintPerCall; j++){
                    (bool success, bytes memory result) = clones[clonesAmount].call(
                        abi.encodeWithSignature(
                            "mintClone(address,uint8,uint256,bytes)",
                            saleAddress,
                            mintPerCall,
                            nftPrice,
                            datacall
                        )
                    );
                    if (!success) return;
                    bool res = abi.decode(result, (bool));
                    if (!res) return;
                }
            if (lastClone % mintPerCall > 0){
                (bool success, bytes memory result) = clones[clonesAmount].call(
                    abi.encodeWithSignature(
                        "mintClone(address,uint8,uint256,bytes)",
                        saleAddress,
                        mintPerCall,
                        nftPrice,
                        datacall
                    )
                );
                if (!success) return;
                bool res = abi.decode(result, (bool));
                if (!res) return;
            }
        }
    }

    function mintWithDeployedClones1155(
      uint256 clonesAmount,
      uint8 txPerClone,
      uint8 mintPerCall,
      bytes calldata datacall,
      bytes calldata supplycall
    ) public onlyOwner {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        (bool success, bytes memory result) = saleAddress.call(supplycall);
        require(success, "invalid supplycall");
        // uint256 totalSupply = abi.decode(result, (uint256));
        uint256 remaining = maxSupply - abi.decode(result, (uint256));
        uint256 lastClone;
        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
            lastClone = remaining % (mintPerCall * txPerClone);
        }
        for (uint256 i; i < clonesAmount; i++) {
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
        }
        if (lastClone > 0) {
            if (lastClone / mintPerCall > 0)
                for (uint256 j; j < lastClone / mintPerCall; j++)
                    MultiMinter(clones[clonesAmount]).mintClone(
                        saleAddress,
                        mintPerCall,
                        nftPrice,
                        datacall
                    );
            if (lastClone % mintPerCall > 0)
                MultiMinter(clones[clonesAmount]).mintClone(
                    saleAddress,
                    lastClone % mintPerCall,
                    nftPrice,
                    datacall
                );
        }
    }

    function hotMintWithoutIDs(
        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall
    ) public onlyOwner {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;

        for (uint256 i; i < clonesAmount; i++) {
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
        }
    }

    function mintFromDeployedClonesWithFund(
        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall
    ) public payable {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();
        uint256 lastClone;
        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
            lastClone = remaining % (mintPerCall * txPerClone);
        }
        for (uint256 i; i < clonesAmount; i++) {
            clones[i].transfer(nftPrice * txPerClone * mintPerCall);
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
        }
        if (lastClone > 0) {
            clones[clonesAmount].transfer(nftPrice * lastClone);
            if (lastClone / mintPerCall > 0)
                for (uint256 j; j < lastClone / mintPerCall; j++)
                    MultiMinter(clones[clonesAmount]).mintClone(
                        saleAddress,
                        mintPerCall,
                        nftPrice,
                        datacall
                    );
            if (lastClone % mintPerCall > 0)
                MultiMinter(clones[clonesAmount]).mintClone(
                    saleAddress,
                    lastClone % mintPerCall,
                    nftPrice,
                    datacall
                );
        }
    }

    function mintFromDeployedClonesWithFund1155(
        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall,
        bytes calldata supplycall
    ) public payable {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        (bool success, bytes memory result) = saleAddress.call(supplycall);
        require(success, "invalid supplycall");
        // uint256 totalSupply = abi.decode(result, (uint256));
        uint256 remaining = maxSupply - abi.decode(result, (uint256));
        uint256 lastClone;
        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
            lastClone = remaining % (mintPerCall * txPerClone);
        }
        for (uint256 i; i < clonesAmount; i++) {
            clones[i].transfer(nftPrice * txPerClone * mintPerCall);
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
        }
        if (lastClone > 0) {
            clones[clonesAmount].transfer(nftPrice * lastClone);
            if (lastClone / mintPerCall > 0)
                for (uint256 j; j < lastClone / mintPerCall; j++)
                    MultiMinter(clones[clonesAmount]).mintClone(
                        saleAddress,
                        mintPerCall,
                        nftPrice,
                        datacall
                    );
            if (lastClone % mintPerCall > 0)
                MultiMinter(clones[clonesAmount]).mintClone(
                    saleAddress,
                    lastClone % mintPerCall,
                    nftPrice,
                    datacall
                );
        }
    }

    function multiMint(
        uint256 _numberOfTokens,
        uint256 _txCount,
        bytes calldata datacall
    ) public payable {
        uint256 totalMint = _numberOfTokens * _txCount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();
        if (totalMint > remaining) {
            _txCount = remaining / _numberOfTokens;
        }

        for (uint256 i; i < _txCount; i++) {
            // mint(_numberOfTokens);
            (bool success, bytes memory data) = saleAddress.call{
                value: nftPrice * _numberOfTokens
            }(datacall);

            
            require(success, "Reverted from sale");
        }
    }

    function mintWithClonesDeploy(
        uint256 clonesQuantity,
        uint8 mintPerClone,
        bytes calldata datacall
    ) public payable validateTx(clonesQuantity, mintPerClone) {
        for (uint256 i; i < clonesQuantity; i++) {
            address payable clone = newClone();
            clone.transfer(nftPrice * mintPerClone);
            MultiMinter(clone).mintClone(
                saleAddress,
                mintPerClone,
                nftPrice,
                datacall
            );
            MultiMinter(clone).setOwner(address(this));
        }
    }

    function mintFromDeployedClonesWithDiffData(
        uint256 clonesAmount,
        uint8 mintPerClone,
        bytes[] calldata datacall
    ) public onlyOwner _validateTx(mintPerClone, clonesAmount) {
        require(clonesAmount <= clones.length, "Too much clones");
        for (uint256 i; i < clonesAmount; i++) {
            MultiMinter(clones[i]).mintClone(
                saleAddress,
                mintPerClone,
                nftPrice,
                datacall[i]
            );
        }
    }

    function mintFromDeployedClonesWithFundWithDiffData(
        uint256 clonesAmount,
        uint8 mintPerClone,
        bytes[] calldata datacall
    ) public payable validateTx(clonesAmount, mintPerClone) {
        for (uint256 i; i < clonesAmount; i++) {
            clones[i].transfer(nftPrice * mintPerClone);
            MultiMinter(clones[i]).mintClone(
                saleAddress,
                mintPerClone,
                nftPrice,
                datacall[i]
            );
        }
    }

    function mintClone(
        address sale,
        uint256 _mintPerClone,
        uint256 _nftPrice,
        bytes calldata datacall
    ) public returns (bool res){
        (bool success, bytes memory data) = sale.call{
            value: _nftPrice * _mintPerClone
        }(datacall);
        res = success;
        require(success, "Reverted from Sale");
    }

    function massWithdrawNft(
        WithdrawData[] memory withdrawData,
        address nftContract,
        address to
    ) public onlyOwner {
        for (uint256 i; i < withdrawData.length; i++) {
            MultiMinter(withdrawData[i].cloneAddress).withdrawNft(
                withdrawData[i].tokenIds,
                nftContract,
                to
            );
        }
    }

    function withdrawNft(
        uint256[] memory tokenIds,
        address sale,
        address to
    ) public {
        require(msg.sender == _owner, "Not owner");

        // NFT(sale).setApprovalForAll(to, true);
        for (uint256 i; i < tokenIds.length; i++) {
            NFT(sale).transferFrom(address(this), to, tokenIds[i]);
        }
    }

    function massWithdraw1155(
      WithdrawData1155[] memory withdrawData,
      address nftContract,
      address to
    ) public onlyOwner {
      for (uint256 i; i < withdrawData.length; i++) {
            MultiMinter(withdrawData[i].cloneAddress).withdrawNft1155(
                withdrawData[i].tokenId,
                nftContract,
                to,
                withdrawData[i].amount
            );
        }
    }

    function withdrawNft1155(
        uint256 tokenId,
        address sale,
        address to,
        uint256 amount
    ) public {
        require(msg.sender == _owner, "Not owner");

        ERC1155(sale).safeTransferFrom(address(this), to, tokenId, amount, "0x");
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        // return this.onERC721Received.selector;
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
      // return this.onERC1155Received.selector;
      return 0xf23a6e61;
    }
}