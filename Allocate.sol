pragma solidity ^ 0.4.20;


library SafeMath {
    function mul(uint a, uint b) internal pure  returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure  returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


// Crowdsale Smart Contract
// This smart contract allows owner on allocating tokens for contributors
// Token owners then can claim tokens 
contract Allocate is Ownable {

    using SafeMath for uint;

    struct Backer {       
        uint tokensToSend; // amount of tokens  sent
        bool claimed;       
    }

    Token public token; // Token contract reference                
    uint public totalTokensAllocated; // Total number of tokens sent to contributors  
    uint public maxCap; // Maximum number of tokens to sell

    mapping(address => Backer) public backers; // contributors list
    address[] public backersIndex; // to be able to iterate through backers for verification.  
    mapping(address => uint) public claimed; // Tokens claimed by contibutors
    uint public totalClaimed;  // total of tokens claimed
    uint public claimCount;  // number of contributors claming tokens
    bool public claimingEnabled; // set this flag to true to allow claiming of tokens
   
    // Events
    event TokensAllocated(address indexed backer, uint tokenAmount);   
    event TokensClaimed(address backer, uint count);

    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initializes all constant and initial values.
    // @param _dollarToEtherRatio {uint} how many dollars are in one eth.  $333.44/ETH would be passed as 33344
    function Allocate() public {               
       
        maxCap = 500000000e8;                                      
    }

    // {fallback function}
    // @notice It will call internal function which handles allocation of Ether and calculates tokens.
    // Contributor will be instructed to specify sufficient amount of gas. e.g. 250,000 
    function () external payable {           
        claimTokens();
    }

    // @notice Specify address of token contract
    // @param _tokenAddress {address} address of token contract
    // @return res {bool}
    function updateTokenAddress(Token _tokenAddress) external onlyOwner() returns(bool res) {
        require(token == address(0));
        token = _tokenAddress;
        return true;
    }

    function updateClaimStatus(bool _claimStatus) external onlyOwner() {
        claimingEnabled = _claimStatus;
    }

    // @notice Fail-safe drain
    function drain(address _adminAddress) external onlyOwner() {

        require(_adminAddress != address(0));
        _adminAddress.transfer(this.balance);               
    }

    // @notice Fail-safe token transfer
    function tokenDrain(address _adminAddress) external onlyOwner() {

        require(_adminAddress != address(0));
        if (!token.transfer(_adminAddress, token.balanceOf(this))) 
            revert();
        
    }

    // @notice contributors can claim tokens after public ICO is finished
    // tokens are only claimable when token address is available and lock-up period reached. 
    function claimTokens() public {
        claimTokensForUser(msg.sender);
    }

    // @notice this function can be called by admin to claim user's token in case of difficulties
    // @param _backer {address} user address to claim tokens for
    function adminClaimTokenForUser(address _backer) external onlyOwner() {
        claimTokensForUser(_backer);
    }

    // @notice return number of contributors
    // @return  {uint} number of contributors   
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }

    // @notice called to send tokens to contributors after ICO.
    // @param _backer {address} address of beneficiary
    // @return true if successful
    function claimTokensForUser(address _backer) internal returns(bool) {       

        require(claimingEnabled);       
        require(token != address(0));  // address of the token is set after ICO
                                        // claiming of tokens will be only possible once address of token
                                        // is set through setToken
           
        Backer storage backer = backers[_backer];
                
        require(!backer.claimed); // if tokens claimed, don't allow refunding     
        uint tokensRemaning = backer.tokensToSend - claimed[_backer];  // see if there are any tokens to claim     
        require(tokensRemaning > 0);   // only continue if there are any tokens to send           

        claimCount++;
           
        claimed[_backer] += tokensRemaning;  // save/add claimed tokens
        backer.claimed = true;
        totalClaimed += tokensRemaning;
        if (!token.transfer(_backer, tokensRemaning)) 
            revert(); // send claimed tokens to contributor account

        TokensClaimed(_backer, tokensRemaning);  
    }

    // @notice It will be called by fallback function whenever ether is sent to it
    // @param _backer {address} address of contributor
    // @param _tokenAmount {uint} amount of tokens to claim
    // @return res {bool} true if transaction was successful
    function allocate(address _backer, uint _tokenAmount) external onlyOwner() returns(bool res) {        
            
        Backer storage backer = backers[_backer];

        if (backer.tokensToSend == 0)
            backersIndex.push(_backer);
        else
            backer.claimed = false;   // allow for multiple additions of tokens for the same account
                                      // claim function will allow multiple claims
         
        backer.tokensToSend += _tokenAmount; // save contributor's total tokens sent
                                             // function will sum tokens added in multiple steps
        totalTokensAllocated += totalTokensAllocated.add(_tokenAmount);     // update the total amount of tokens sent      

        require(totalTokensAllocated <= maxCap);  
           
        //if (!token.transfer(_backer, _tokenAmount)) // Transfer tokens. Leave this as alternative. 
        //    revert();         

        TokensAllocated(_backer, _tokenAmount); // Register event
        return true;
    }    

}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// The token
contract Token is ERC20, Ownable {
    
    using SafeMath for uint;
    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = "v0.1";   
    uint public totalSupply;
    bool public locked;           
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public migrationMaster;
    address public migrationAgent;
    address public allocateAddress;
    uint256 public totalMigrated;

    // Lock transfer for contributors during the ICO 
    modifier onlyUnlocked() {
        if (msg.sender != allocateAddress && locked) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != allocateAddress) 
            revert();
        _;
    }

    // The SOCX Token created with the time at which the crowdsale ends
    function Token(address _allocateAddress) public {
        // Lock the transfCrowdsaleer function during the crowdsale
        locked = true; // Lock the transfer of tokens during the crowdsale       
        totalSupply = 500000000e8;
        name = "Veiris"; // Set the name for display purposes
        symbol = "VeE"; // Set the symbol for display purposes
        decimals = 8; // Amount of decimals for display purposes
        allocateAddress = _allocateAddress;              
        balances[allocateAddress] = totalSupply;       
    }

    function unlock() public onlyAuthorized {
        locked = false;
    }

    function lock() public onlyAuthorized {
        locked = true;
    }

    function resetCrowdSaleAddress(address _newCrowdSaleAddress) external onlyAuthorized() {
        allocateAddress = _newCrowdSaleAddress;
    }
    
    // @notice transfer tokens to given address 
    // @param _to {address} address or recipient
    // @param _value {uint} amount to transfer
    // @return  {bool} true if successful  
    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice transfer tokens from given address to another address
    // @param _from {address} from whom tokens are transferred 
    // @param _to {address} to whom tokens are transferred
    // @parm _value {uint} amount of tokens to transfer
    // @return  {bool} true if successful   
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require(balances[_from] >= _value); // Check if the sender has enough                            
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal        
        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    // @notice to query balance of account
    // @return _owner {address} address of user to query balance 
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // @notice to query of allowance of one user to the other
    // @param _owner {address} of the owner of the account
    // @param _spender {address} of the spender of the account
    // @return remaining {uint} amount of remaining allowance
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}