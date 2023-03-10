// SPDX-License-Identifier: MIT OR Apache-2.0

/*
W: https://kingdomofants.io 

                ▒▒██            ██▒▒                
                    ██        ██                    
                    ██  ████  ██                    
                    ████▒▒▒▒████                    
████              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ████
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
██▒▒██            ██▒▒██▒▒▒▒██▒▒██            ██▒▒██
  ██              ██▒▒▒▒▒▒▒▒▒▒▒▒██              ██  
    ██            ██▒▒██▒▒▒▒██▒▒██            ██    
      ██          ▓▓▒▒▒▒████▒▒▒▒██          ██      
        ██          ████████████          ██        
          ██          ██▒▒▒▒██          ██          
            ██████████▒▒▒▒▒▒▒▒██████████            
                    ██▒▒▒▒▒▒▒▒██                    
          ████████████▒▒▒▒▒▒▒▒████████████          
        ██          ██▒▒▒▒▒▒▒▒██          ██        
      ██            ██▒▒▒▒▒▒▒▒██            ██      
    ██            ████▒▒▒▒▒▒▒▒████            ██    
  ██            ██    ████████    ██            ██  
██▒▒██        ██    ██▒▒▒▒▒▒▒▒██    ██        ██▒▒██
██▒▒██      ██      ██▒▒▒▒▒▒▒▒██      ██      ██▒▒██
████      ██        ██▒▒▒▒▒▒▒▒██        ██      ████
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██          ██▒▒▒▒▒▒▒▒██          ██        
        ██            ██▒▒▒▒██            ██        
      ████            ██▒▒▒▒██            ████      
    ██▒▒██              ████              ██▒▒██    
    ██████                                ██████    

* Howdy folks! Thanks for glancing over our contracts
* Y'all have a nice day! Enjoy the game
*/

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./interfaces/IANTShop.sol";

contract ANTShop is ERC1155, IANTShop, Ownable, Pausable {

    // minters
    mapping(address => bool) private minters;
    // token type info
    mapping(uint256 => TypeInfo) private typeInfo;

    // modifier to check _msgSender has minter role
    modifier onlyMinter() {
        require(minters[_msgSender()], "ANTFood: Caller is not the minter");
        _;
    }

    // Mint event
    event Mint(uint256 typeId, address owner, uint256 quantity);
    // Burn event
    event Burn(uint256 typeId, address owner, uint256 quantity);

    constructor () ERC1155('') {

    }

    /**
    * ██ ███    ██ ████████
    * ██ ████   ██    ██
    * ██ ██ ██  ██    ██
    * ██ ██  ██ ██    ██
    * ██ ██   ████    ██
    * This section has internal only functions
    */

    /**
    * @notice Transfer ETH and return the success status.
    * @dev This function only forwards 30,000 gas to the callee.
    * @param to Address for ETH to be send to
    * @param value Amount of ETH to send
    */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /**
    * ███████ ██   ██ ████████
    * ██       ██ ██     ██
    * █████     ███      ██
    * ██       ██ ██     ██
    * ███████ ██   ██    ██
    * This section has external functions
    */

    /**
    * @notice returns info about a Type
    * @param typeId the typeId to return info for
    */
    function getInfoForType(uint256 typeId) external override view returns (TypeInfo memory) {
        require(typeInfo[typeId].isSet, "ANTShop: invalid type id");
        return typeInfo[typeId];
    }

    /**
    * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    * @dev See {IERC721Metadata-tokenURI}.
    */
    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeInfo[typeId].isSet, "ANTShop: invalid type id");
        return typeInfo[typeId].baseURI;
    }

    /**
    *   ██████  ██     ██ ███    ██ ███████ ██████
    *  ██    ██ ██     ██ ████   ██ ██      ██   ██
    *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
    *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
    *   ██████   ███ ███  ██   ████ ███████ ██   ██
    * This section will have all the internals set to onlyOwner
    */

    /**
    * @notice Mint tokens to recipient address
    * @dev This function can only be called by the minter
    * @param typeId typeId for setting the token info 0 => ANTFood, 1 => LevelingPotion, ...
    * @param quantity the number of tokens to mint
    * @param recipient recipient address for mint token
    */

    function mint(uint256 typeId, uint256 quantity, address recipient) external override whenNotPaused onlyMinter {
        require(typeInfo[typeId].isSet, "ANTShop: invalid type id");
        typeInfo[typeId].mints += quantity;
        _mint(recipient, typeId, quantity, '');
        emit Mint(typeId, recipient, quantity);
    }

    /**
    * @notice Burn a token
    * @dev This function can only be called by the minter
    * @param typeId typeId for setting the token info 0 => ANTFood, 1 => LevelingPotion, ...
    * @param quantity the number of tokens to burn
    * @param burnFrom token owner address to burn
    */

    function burn(uint256 typeId, uint256 quantity, address burnFrom) external override whenNotPaused onlyMinter {
        require(typeInfo[typeId].mints > 0, "ANTShop: None minted");
        typeInfo[typeId].burns += quantity;
        _burn(burnFrom , typeId, quantity);
        emit Burn(typeId, burnFrom, quantity);
    }

    /**
    * @notice Set Token type info _typeId = 0 => ANTFood, _typeID = 1 => LevelingPotion, ...
    * @dev This function can only be called by the minter
    * @param _typeId typeId for setting the token info
    * @param _baseURI tokenURI for token
    */

    function setTokenTypeInfo(uint256 _typeId, string memory _baseURI) external onlyOwner {
        typeInfo[_typeId].baseURI = _baseURI;
        typeInfo[_typeId].isSet = true;
    }

    /**
    * enables owner to pause / unpause contract
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
    * @notice Allows owner to withdraw ETH funds to an address
    * @dev wraps _user in payable to fix address -> address payable
    * @param to Address for ETH to be send to
    * @param amount Amount of ETH to send
    */
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(_safeTransferETH(to, amount));
    }

    /**
    * @notice Allows ownder to withdraw any accident tokens transferred to contract
    * @param _tokenContract Address for the token
    * @param to Address for token to be send to
    * @param amount Amount of token to send
    */
    function withdrawToken(
        address _tokenContract,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(to, amount);
    }
}