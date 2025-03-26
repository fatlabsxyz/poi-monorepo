// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ITornado {
  function withdraw(
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) external;

  function denomination() external returns (uint256);

  function nullifierHashes(bytes32 _nullifierHash) external returns (bool);
}
