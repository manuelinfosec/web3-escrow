  
pragma solidity 0.7.0;

// SPDX-License-Identifier: MIT


/**
ensure that the correct salt is returned from Escrow contract
*/
contract EscrowSalt {
        
    function getSalt(address _addr, address _addr2, string memory _salt) public pure returns(bytes32 newsalt){
        newsalt = keccak256(abi.encode(_addr, _addr2, _salt));
        return newsalt;
    }
}