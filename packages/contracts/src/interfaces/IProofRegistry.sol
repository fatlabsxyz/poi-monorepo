// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ITornado} from './ITornado.sol';

interface IProofRegistry {
  /*///////////////////////////////////////////////////////////////
                            ERRORS
    ////////////////////////////////////////////////////////////////*/

  /**
   * @notice Thrown when a non-postman account attempts to update the membership root
   */
  error OnlyPostman();

  /**
   * @notice Thrown when the membership proof verification fails
   */
  error InvalidMembershipProof();

  /**
   * @notice Thrown when ETH transfer fails
   */
  error FailedToSendETH();

  /**
   * @notice Thrown when either root or IPFS hash is zero
   */
  error InvalidRootOrIPFSHash();

  /**
   * @notice Thrown when the withdrawn amount doesn't match expected value
   */
  error InvalidWithdrawnAmount();

  /**
   * @notice Thrown when recipient address is zero
   */
  error InvalidRecipient();

  /**
   * @notice Thrown when the nullifier hash has already been spent
   */
  error NullifierHashUnspent();

  /**
   * @notice Thrown when insufficient fee is paid for proof submission
   */
  error InsufficientFeePaid();

  /**
   * @notice Thrown when attempting to interact with an unknown Tornado pool
   */
  error UnknownPool();

  /**
   * @notice Thrown when attempting to submit a proof for an already used nullifier hash
   */
  error ProofAlreadySubmittedForNullifierHash();

  /*///////////////////////////////////////////////////////////////
                            EVENTS
    ////////////////////////////////////////////////////////////////*/

  /**
   * @notice Emitted when a new membership root is updated
   * @param _root The new membership root
   * @param _index The index of the new root
   * @param _ipfsHash The IPFS hash containing the root data
   */
  event MembershipRootUpdated(uint256 _root, bytes32 _ipfsHash, uint256 _index);

  /**
   * @notice Emitted when fees are withdrawn from the contract
   * @param _recipient The address receiving the fees
   * @param _amount The amount of fees withdrawn
   */
  event FeesWithdrawn(address _recipient, uint256 _amount);

  /**
   * @notice Emitted when the fee basis points are updated
   * @param _previous The previous fee basis points
   * @param _current The new fee basis points
   */
  event FeeUpdated(uint256 _previous, uint256 _current);

  /**
   * @notice Emitted when a postman's status is updated
   * @param _account The address of the postman
   * @param _isPostman The new postman status
   */
  event PostmanUpdated(address _account, bool _isPostman);

  event MembershipProofSubmitted(
    address indexed _caller, ITornado indexed _pool, bytes32 indexed _nullifierHash, uint256 _feePaid
  );

  event WithdrawnAndProved(
    address indexed _caller, ITornado indexed _pool, bytes32 _nullifierHash, uint256 indexed _membershipRoot
  );

  /*///////////////////////////////////////////////////////////////
                          VARIABLES
    ////////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the mapping of nullifier hash to root
   * @param _nullifierHash The nullifier hash to query
   * @return The corresponding root
   */
  function proofRegistry(uint256 _nullifierHash) external view returns (uint256);

  /**
   * @notice Returns whether an account is a postman
   * @param _account The account to query
   * @return Whether the account is a postman
   */
  function postmen(address _account) external view returns (bool);

  /**
   * @notice Returns whether a Tornado pool is known to the registry
   * @param _pool The pool to query
   * @return Whether the pool is known
   */
  function isKnownPool(ITornado _pool) external view returns (bool);

  /**
   * @notice Returns the root at a specific index
   * @param _index The index to query
   * @return The root at the index
   */
  function roots(uint256 _index) external view returns (uint256);

  /**
   * @notice Returns the current root index
   * @return The current root index
   */
  function currentRootIndex() external view returns (uint256);

  /**
   * @notice Returns the current fee basis points
   * @return The current fee basis points
   */
  function feeBPS() external view returns (uint256);

  /**
   * @notice Returns the latest membership root
   * @return The latest membership root
   */
  function latestMembershipRoot() external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                            LOGIC
    ////////////////////////////////////////////////////////////////*/

  /**
   * @notice Initializes the contract with owner and fee settings
   * @dev Initializes OpenZeppelin upgradeable contracts
   * @param _owner The owner of the contract
   * @param _feeBPS The initial fee basis points
   */
  function initialize(address _owner, uint256 _feeBPS) external;

  /**
   * @notice Updates the membership root with a new value
   * @dev Only callable by postmen
   * @param _root The new root to set
   * @param _ipfsHash The IPFS hash containing the root data
   */
  function updateRoot(uint256 _root, bytes32 _ipfsHash) external;

  /**
   * @notice Updates the postman status of an account
   * @dev Only callable by owner
   * @param _account The account to update
   * @param _newStatus The new postman status
   */
  function updatePostman(address _account, bool _newStatus) external;

  /**
   * @notice Updates the fee basis points
   * @dev Only callable by owner
   * @param _newFeeBPS The new fee basis points
   */
  function updateFees(uint256 _newFeeBPS) external;

  /**
   * @notice Submits a membership proof for a Tornado pool
   * @dev Requires payment of fees and valid proof verification
   * @param _pool The Tornado pool to submit proof for
   * @param _membershipProof The membership proof data
   * @param _nullifierHash The nullifier hash for the proof
   */
  function submitMembershipProof(
    ITornado _pool,
    bytes memory _membershipProof,
    bytes32 _nullifierHash
  ) external payable;

  /**
   * @notice Withdraws funds from a Tornado pool and posts membership proof
   * @dev Handles fee calculations and transfers
   * @param _membershipProof The membership proof data
   * @param _withdrawProof The withdrawal proof data
   * @param _root The root for verification
   * @param _nullifierHash The nullifier hash
   * @param _recipient The address to receive the funds
   * @param _relayer The address of the relayer
   * @param _fee The fee for the transaction
   * @param _refund The refund amount
   * @param _pool The Tornado pool to withdraw from
   */
  function withdrawAndPostMembershipProof(
    bytes memory _membershipProof,
    bytes memory _withdrawProof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address _recipient,
    address _relayer,
    uint256 _fee,
    uint256 _refund,
    ITornado _pool
  ) external;

  /**
   * @notice Withdraws collected fees to a recipient
   * @dev Only callable by owner
   * @param _recipient The address to receive the fees
   */
  function withdrawFees(address _recipient) external;
}
