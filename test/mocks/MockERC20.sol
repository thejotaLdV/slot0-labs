// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Token ERC20 minimo para fixtures de test: cualquiera puede acuñar
///         cantidades arbitrarias, sin ninguna restriccion de acceso. Uso
///         exclusivo de los tests, no forma parte de ningun laboratorio.
contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
