// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./contracts/ExxaFund101.sol";

contract MyTokenTest is ExxaTokken {

    function testTokenInitialValues() public {
        Assert.equal(name(), "MyToken", "token name did not match");
        Assert.equal(symbol(), "MTK", "token symbol did not match");
        Assert.equal(decimals(), 18, "token decimals did not match");
        Assert.equal(totalSupply(), 0, "token supply should be zero");
    }
}
