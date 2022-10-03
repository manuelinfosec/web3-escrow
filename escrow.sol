// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;
import 'https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/contracts/src/v0.6/ChainlinkClient.sol';


contract Escrow is ChainlinkClient {
  
    // uint256 public ethereumPrice;
    address payable public sender;
    address payable public receiver;
    address payable private owner;
    uint256 public amount;
    string public btcAddress;
    uint256 public lockTimestamp;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    bool private initialised;

    event TxCompleted(address indexed sender, address indexed receiver, uint256 btcValue, uint256 ethValue);
    
    /**
     * Network: Ropsten
     */
    constructor() public {
        setPublicChainlinkToken();
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        // fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function init(address payable _sender, address payable _receiver, uint256 _amount, string calldata _btcAddress, uint256 _lockTimestamp, uint256 _fee) public {
        require(!initialised);
        sender = _sender;
        receiver = _receiver;
        amount = _amount;
        btcAddress = _btcAddress;
        lockTimestamp = _lockTimestamp;
        initialised = true;
        owner = msg.sender;
        fee = _fee;
        retry();
    }

    function retry() public returns (bytes32 requestId) {
        string memory url = this.getReqURL(btcAddress);
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", url);
        request.add("path", "total_received");
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function getReqURL(string memory _btcAddress) public pure returns(string memory){
        return string(abi.encodePacked("https://api.blockcypher.com/v1/btc/test3/addrs/", _btcAddress, "/balance"));
    }
    
    function fulfill(bytes32 _requestId, uint256 total_received) public recordChainlinkFulfillment(_requestId){
        if(total_received >= amount){
            uint256 ethValue = (address(this)).balance;
            receiver.transfer(ethValue);
            TxCompleted(sender, receiver, total_received, ethValue);
            selfdestruct(owner);
        }
    }

    function recoverFund() public {
        require(now > lockTimestamp,"Time not elapse to recover fund");
        uint256 ethValue = (address(this)).balance;
        sender.transfer(ethValue);
        selfdestruct(owner);
    }
}