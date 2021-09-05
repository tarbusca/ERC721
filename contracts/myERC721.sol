pragma solidity ^0.8.0;
//"SPDX-License-Identifier: UNLICENSED"
/**
 * Create an ERC721 Token with the following requirements

 * user can only buy tokens when the sale is started
 * the sale should be ended within 30 days
 * the owner can set base URI
 * nthe owner can set the price of NFT
 * NFT minting hard limit is 100
 */
 
/**
 * Tariq Saeed 
 * PIAIC 111569
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";    
import "@openzeppelin/contracts/utils/Strings.sol";    
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract myERC721 is ERC165, IERC721, Ownable {
    
    using Strings for uint256;
    using Address for address;
    
    uint _totalSupply;              //Total tokens
    string private _name;           // Token name
    string private _symbol;         // Token symbol
    string private _baseURI;        // Base URI
    uint256 private _tokenSaleDate; 
    uint256 private _tokenSaleEndDate; 
    uint256 private _tokenPrice;
    uint256 private _currSupply =1;    //last token id;
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    
    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;
    //1 -> mudassir

    /**
    *@dev For a given account, for a given operator, store whether that operator is
    * allowed to transfer and modify assets on behalf of them.
    */
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    //qasim -> mudassir = true
    
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    
     constructor ()  {      //string memory name, string memory symbol, string memory baseuri
        _name = "CryptoPokemon";
        _symbol = "CPKMN";
        _totalSupply = 100;
        _baseURI = "https://my-json-server.typicode.com/tarbusca/testNFT/tokens/";
    }
    
    modifier isSaleOn() {
        require(block.timestamp >= _tokenSaleDate && block.timestamp <= _tokenSaleEndDate, "Sorry, not a Sale period");
        _;
    }
    function startSaleNow(uint256 tokenprice) external onlyOwner {
        _tokenSaleDate = block.timestamp;
        _tokenSaleEndDate = _tokenSaleDate + 30 days;
        _tokenPrice = tokenprice;
    }
    
    function changeTokenPrice (uint256 newTokenprice) external onlyOwner {
        _tokenPrice = newTokenprice;  
    }
    
    function _mint (address to) payable public isSaleOn {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_currSupply <= _totalSupply, "No more tokens left for minting");
        require(msg.value >= _tokenPrice, "Not enough ethers sent");

       uint256 newToken = _getNextTokenId();
       _owners[newToken] = to;
       _balances[to] += 1; //balances[to]++;
       _tokenURIs[newToken] = tokenURI(newToken);
       _incrementTokenId();
      
    } 
    
    function _getNextTokenId() private view returns (uint256) {
        return _currSupply; //work on it later
    }

    function _incrementTokenId() private {
        _currSupply++;
    }    
    
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : "";

    }    
    
    function _exists (uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function name() public view  returns (string memory) {
        return _name;
    }
    function symbol() public view  returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view  returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _totalSupply;
    }    
    
    function balanceOf(address owner) external view override returns (uint256 balance) {
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) external view override returns (address owner){
        return _owners[tokenId];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
       // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: Not the owner of this token");
        require(to != address(0), "ERC721: transfer to the zero address not allowed");
        
        // Clear approvals from the previous owner
       // this.approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    function approve(address to, uint256 tokenId) external override {
        require(_exists(tokenId), "ERC721: can not approve for nonexistent token");
        require(to != _tokenApprovals[tokenId], "ERC721: Current Owner and Approver can not be same");
        _tokenApprovals[tokenId] = to;
        emit Approval(this.ownerOf(tokenId), to, tokenId);
    }
    function getApproved(uint256 tokenId) public override view returns (address operator){
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool _approved) external override {
        _operatorApprovals[_msgSender()][operator] = _approved;
        emit ApprovalForAll(_msgSender(), operator, _approved);
    }
    function isApprovedForAll(address owner, address operator) public override view returns (bool){
        return _operatorApprovals[owner][operator];
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        _safeTransfer(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transferring to non ERC721Receiver implementer");
    } 
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = this.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }    
     /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
