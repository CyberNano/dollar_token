contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StableToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        if (balancesVersions[version].balances[msg.sender] >= _value && balancesVersions[version].balances[_to] + _value > balancesVersions[version].balances[_to]) {
        //if (balancesVersions[version].balances[msg.sender] >= _value && _value > 0) {
            balancesVersions[version].balances[msg.sender] -= _value;
            balancesVersions[version].balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balancesVersions[version].balances[_from] >= _value && allowedVersions[version].allowed[_from][msg.sender] >= _value && balancesVersions[version].balances[_to] + _value > balancesVersions[version].balances[_to]) {
        //if (balancesVersions[version].balances[_from] >= _value && allowedVersions[version].allowed[_from][msg.sender] >= _value && _value > 0) {
            balancesVersions[version].balances[_to] += _value;
            balancesVersions[version].balances[_from] -= _value;
            allowedVersions[version].allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balancesVersions[version].balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowedVersions[version].allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowedVersions[version].allowed[_owner][_spender];
    }

    //this is so we can reset the balances while keeping track of old versions
    uint public version = 0;

    struct BalanceStruct {
      mapping(address => uint256) balances;
    }
    mapping(uint => BalanceStruct) balancesVersions;

    struct AllowedStruct {
      mapping (address => mapping (address => uint256)) allowed;
    }
    mapping(uint => AllowedStruct) allowedVersions;

    uint256 public totalSupply;

}