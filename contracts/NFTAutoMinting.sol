// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

contract NFTAutoMinting is ERC721, ERC721URIStorage, Ownable, ERC721Enumerable, IERC721Receiver {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    string baseURI;
    string tURI;
    string public baseExtension = "";
    uint256 public maxSupply = 10000;
    bool public paused = false;

    event TokenURI (
      string tokenUri, uint256 tokenId
    );

    constructor (string memory _name, string memory _symbol, string memory _initBaseURI) ERC721 (_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setTURI(string memory _tUri) private {
        tURI = _tUri;
    }

    function getTURI() public view returns (string memory) {
        return tURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function getActualToken() public view returns (uint) {
        return  _tokenIds.current();
    }

    function createToken() public payable {
        payable(address(this)).transfer(msg.value);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        //_setTokenURI(newItemId, string(abi.encodePacked(baseURI, newItemId.toString(), baseExtension)));
        _setTokenURI(newItemId, string(abi.encodePacked(baseURI, newItemId.toString(), baseExtension)));
        setTURI(string(abi.encodePacked(baseURI, newItemId.toString(), baseExtension)));
        //emit TokenURI(string(abi.encodePacked(baseURI, newItemId.toString(), baseExtension)), newItemId);
        emit TokenURI(string(abi.encodePacked(baseURI, newItemId.toString())), newItemId);
    }

    function getTokenBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(address depositAddress) public payable onlyOwner {
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
        (bool os, ) = payable(depositAddress).call{value: address(this).balance}("");
        require(os);
    // =============================================================================
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )external override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable {}
}