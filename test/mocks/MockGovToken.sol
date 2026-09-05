// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Token de gobernanza mínimo con checkpoints de balance por bloque,
///         para que un Governor pueda leer el poder de voto de un bloque
///         pasado en vez del balance instantáneo.
/// @dev Implementación propia y autocontenida (no ERC20Votes de OpenZeppelin)
///      para no depender de una API que cambia entre versiones del paquete.
///      Uso exclusivo de los tests, no forma parte de ningún laboratorio.
contract MockGovToken {
    string public constant name = "GovToken";
    string public constant symbol = "GOV";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    struct Checkpoint {
        uint256 blockNumber;
        uint256 balance;
    }
    mapping(address => Checkpoint[]) private _checkpoints;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        _writeCheckpoint(to);
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "Insufficient allowance");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        _writeCheckpoint(from);
        _writeCheckpoint(to);
        emit Transfer(from, to, amount);
    }

    function _writeCheckpoint(address account) internal {
        Checkpoint[] storage checkpoints = _checkpoints[account];
        if (checkpoints.length > 0 && checkpoints[checkpoints.length - 1].blockNumber == block.number) {
            checkpoints[checkpoints.length - 1].balance = balanceOf[account];
        } else {
            checkpoints.push(Checkpoint({blockNumber: block.number, balance: balanceOf[account]}));
        }
    }

    /// @notice Balance de `account` en el bloque `blockNumber` (el checkpoint
    ///         más reciente con blockNumber <= el pedido). Búsqueda binaria.
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        Checkpoint[] storage checkpoints = _checkpoints[account];
        if (checkpoints.length == 0 || checkpoints[0].blockNumber > blockNumber) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = checkpoints.length;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (checkpoints[mid].blockNumber <= blockNumber) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return checkpoints[low - 1].balance;
    }
}
