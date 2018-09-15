contract CustodialWalletInterface {

    function balanceOf(address token, address tokenOwner) public constant returns (uint balance);
    function allowance(address token, address tokenOwner, address spender) public constant returns (uint remaining);

    function approveTokens(address spender, address token, uint tokens) public returns (bool success);
    function transferTokens(address to, address token, uint tokens) public returns (bool success);
    function transferTokensFrom(address from, address to, address token, uint tokens) public returns (bool success);

    function depositTokens(address from, address token, uint256 tokens ) public returns (bool success);
    function withdrawTokens(address token, uint256 tokens) public returns (bool success);
    function withdrawTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success);
}
