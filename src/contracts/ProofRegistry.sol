// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {OwnableUpgradeable} from 'openzeppelin-upgradeable/access/OwnableUpgradeable.sol';
import {UUPSUpgradeable} from 'openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from 'openzeppelin-upgradeable/utils/ReentrancyGuardUpgradeable.sol';

import {IProofRegistry} from 'interfaces/IProofRegistry.sol';
import {ITornado} from 'interfaces/ITornado.sol';
import {IVerifier} from 'interfaces/IVerifier.sol';

/**
 * @title ProofRegistry
 * @author FAT SOLUTIONS
 * @notice Registry for membership proofs related to Tornado Cash-like pools
 * @dev Implements IProofRegistry and uses upgradeability patterns
 */
contract ProofRegistry is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IProofRegistry {
  /// @inheritdoc IProofRegistry
  mapping(uint256 _nullifierHash => uint256 _root) public proofRegistry;

  /// @inheritdoc IProofRegistry
  mapping(address _account => bool _isPostman) public postmen;

  /// @inheritdoc IProofRegistry
  mapping(ITornado _pool => bool _known) public isKnownPool;

  /// @inheritdoc IProofRegistry
  mapping(uint256 _index => uint256 _root) public roots;

  /// @dev Scalar field size for the SNARK proving system
  uint256 internal constant _SNARK_SCALAR_FIELD =
    21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617;

  /// @dev The verifier contract used to verify SNARK proofs
  IVerifier public constant verifier = IVerifier(0xce172ce1F20EC0B3728c9965470eaf994A03557A);

  /// @inheritdoc IProofRegistry
  uint256 public currentRootIndex;

  /// @inheritdoc IProofRegistry
  uint256 public feeBPS;

  /**
   * @inheritdoc IProofRegistry
   */
  function initialize(address _owner, uint256 _feeBPS) external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init(_owner);
    __ReentrancyGuard_init();

    feeBPS = _feeBPS;

    // Initialize known Tornado pools
    isKnownPool[ITornado(0x12D66f87A04A9E220743712cE6d9bB1B5616B8Fc)] = true; // 0.1 ETH pool
    isKnownPool[ITornado(0x47CE0C6eD5B0Ce3d3A51fdb1C52DC66a7c3c2936)] = true; // 1 ETH pool
    isKnownPool[ITornado(0x910Cbd523D972eb0a6f4cAe4618aD62622b39DbF)] = true; // 10 ETH pool
    isKnownPool[ITornado(0xA160cdAB225685dA1d56aa342Ad8841c3b53f291)] = true; // 100 ETH pool
  }

  /**
   * @inheritdoc IProofRegistry
   */
  function latestMembershipRoot() public view returns (uint256) {
    return roots[currentRootIndex];
  }

  /**
   * @inheritdoc IProofRegistry
   */
  function updateRoot(uint256 _root, bytes32 _ipfsHash) external {
    require(postmen[msg.sender], OnlyPostman());
    require(_root != 0 && _ipfsHash != 0, InvalidRootOrIPFSHash());

    ++currentRootIndex;

    roots[currentRootIndex] = _root;

    emit MembershipRootUpdated(_root, _ipfsHash, currentRootIndex);
  }

  /**
   * @inheritdoc IProofRegistry
   */
  function updatePostman(address _account, bool _newStatus) external onlyOwner {
    postmen[_account] = _newStatus;

    emit PostmanUpdated(_account, _newStatus);
  }

  /**
   * @inheritdoc IProofRegistry
   */
  function updateFees(uint256 _newFeeBPS) external onlyOwner {
    uint256 _previousFeeBPS = feeBPS;
    feeBPS = _newFeeBPS;

    emit FeeUpdated(_previousFeeBPS, _newFeeBPS);
  }

  /**
   * @inheritdoc IProofRegistry
   */
  function submitMembershipProof(
    ITornado _pool,
    bytes memory _membershipProof,
    bytes32 _nullifierHash
  ) external payable {
    require(isKnownPool[_pool], UnknownPool());
    require(proofRegistry[uint256(_nullifierHash)] == 0, ProofAlreadySubmittedForNullifierHash());

    uint256 _requiredFee = (_pool.denomination() * feeBPS) / 10_000;
    require(msg.value == _requiredFee, InsufficientFeePaid());

    require(_pool.nullifierHashes(_nullifierHash), NullifierHashUnspent());

    uint256 _latestRoot = latestMembershipRoot();

    require(
      verifier.verifyProof(_membershipProof, [_latestRoot, uint256(_nullifierHash), 0, 0, 0, 0]),
      InvalidMembershipProof()
    );

    proofRegistry[uint256(_nullifierHash)] = _latestRoot;

    emit MembershipProofSubmitted(msg.sender, _pool, _nullifierHash, _requiredFee);
  }

  /**
   * @inheritdoc IProofRegistry
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
  ) external nonReentrant {
    require(isKnownPool[_pool], UnknownPool());

    uint256 _withdrawProofHash = uint256(
      keccak256(abi.encodePacked(_pool, _withdrawProof, _root, _nullifierHash, address(this), _relayer, _fee, _refund))
    ) % _SNARK_SCALAR_FIELD;

    uint256 _membershipRoot = latestMembershipRoot();

    require(
      verifier.verifyProof(
        _membershipProof,
        [_membershipRoot, uint256(_nullifierHash), uint256(uint160(_recipient)), _withdrawProofHash, 0, 0]
      ),
      InvalidMembershipProof()
    );

    uint256 _balanceBefore = address(this).balance;

    _pool.withdraw(_withdrawProof, _root, _nullifierHash, payable(address(this)), payable(_relayer), _fee, _refund);

    uint256 _withdrawnAmount = _pool.denomination() - _fee;
    require(address(this).balance == _balanceBefore + _withdrawnAmount, InvalidWithdrawnAmount());

    uint256 _feesOwed = (_withdrawnAmount * feeBPS) / 10_000;
    uint256 _amountAfterFees = _withdrawnAmount - _feesOwed;
    _transfer(_recipient, _amountAfterFees);

    emit WithdrawnAndProved(msg.sender, _pool, _nullifierHash, _membershipRoot);
  }

  /**
   * @inheritdoc IProofRegistry
   */
  function withdrawFees(address _recipient) external onlyOwner nonReentrant {
    uint256 _balance = address(this).balance;
    _transfer(_recipient, _balance);

    emit FeesWithdrawn(_recipient, _balance);
  }

  /**
   * @dev Internal helper to transfer ETH to a recipient
   * @param _recipient Address to receive ETH
   * @param _amount Amount of ETH to transfer
   */
  function _transfer(address _recipient, uint256 _amount) internal {
    require(_recipient != address(0), InvalidRecipient());

    (bool _success,) = _recipient.call{value: _amount}('');
    require(_success, FailedToSendETH());
  }

  /**
   * @dev Authorizes an upgrade to a new implementation
   * @param newImplementation The address of the new implementation
   */
  function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable) onlyOwner {}

  /**
   * @dev Fallback function to receive ETH
   */
  receive() external payable {}
}
