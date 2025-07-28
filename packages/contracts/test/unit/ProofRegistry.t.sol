// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

import {IProofRegistry, ProofRegistry} from 'contracts/ProofRegistry.sol';

import {IERC1967} from 'openzeppelin/interfaces/IERC1967.sol';

import {ITornado} from 'interfaces/ITornado.sol';
import {IVerifier} from 'interfaces/IVerifier.sol';
import {ERC1967Proxy} from 'openzeppelin/proxy/ERC1967/ERC1967Proxy.sol';

contract ProofRegistryForTest is ProofRegistry {
  function mockRoot(uint256 _root) public {
    ++currentRootIndex;
    roots[currentRootIndex] = _root;
  }

  function mockNullifierStatus(bytes32 _nullifierHash, uint256 _root) public {
    proofRegistry[uint256(_nullifierHash)] = _root;
  }
  
  function mockKnownPool(ITornado _pool) public {
    isKnownPool[_pool] = true;
  }
}

contract UnitProofRegistry is Test {
  ProofRegistryForTest public registry;
  address public OWNER = makeAddr('OWNER');
  address public POSTMAN = makeAddr('POSTMAN');
  uint256 public FEE = 25; // 0.25 %

  ITornado public point_one_eth_pool = ITornado(0x12D66f87A04A9E220743712cE6d9bB1B5616B8Fc);
  ITornado public one_eth_pool = ITornado(0x47CE0C6eD5B0Ce3d3A51fdb1C52DC66a7c3c2936);
  ITornado public hundred_eth_pool = ITornado(0xA160cdAB225685dA1d56aa342Ad8841c3b53f291);

  address public verifier = 0xce172ce1F20EC0B3728c9965470eaf994A03557A;

  uint256 internal constant _SNARK_SCALAR_FIELD =
    21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617;

  error InvalidInitialization();
  error OnlyOwner();
  error OwnableUnauthorizedAccount(address account);
  error FeeTooHigh();
  error InvalidIPFSCIDLength();

  function setUp() public {
    ProofRegistryForTest _impl = new ProofRegistryForTest();

    bytes memory _initializationData = abi.encodeWithSelector(ProofRegistry.initialize.selector, OWNER, FEE);

    ERC1967Proxy _proxy = new ERC1967Proxy(address(_impl), _initializationData);

    registry = ProofRegistryForTest(payable(address(_proxy)));
  }

  function _mockAndExpect(address _contract, bytes memory _call, bytes memory _return) internal {
    vm.mockCall(_contract, _call, _return);
    vm.expectCall(_contract, _call);
  }

  receive() external payable {}
}

contract UnitInitialization is UnitProofRegistry {
  function test_initializationValues() public view {
    assertEq(registry.owner(), OWNER);
    assertEq(registry.feeBPS(), FEE);

    assertTrue(registry.isKnownPool(ITornado(0x12D66f87A04A9E220743712cE6d9bB1B5616B8Fc)));
    assertTrue(registry.isKnownPool(ITornado(0x47CE0C6eD5B0Ce3d3A51fdb1C52DC66a7c3c2936)));
    assertTrue(registry.isKnownPool(ITornado(0xA160cdAB225685dA1d56aa342Ad8841c3b53f291)));
  }

  function test_canNotReinitialize(address _owner, uint256 _fee) public {
    vm.prank(OWNER);

    vm.expectRevert(InvalidInitialization.selector);
    registry.initialize(_owner, _fee);
  }
}

contract UnitUpdateRoot is UnitProofRegistry {
  function test_updateRootHappyPath(address _postman, uint256 _root, string memory _ipfsCID) public {
    vm.assume(_root != 0);
    vm.assume(bytes(_ipfsCID).length >= 32 && bytes(_ipfsCID).length <= 64);

    vm.prank(OWNER);
    registry.updatePostman(_postman, true);

    vm.expectEmit(address(registry));
    emit IProofRegistry.MembershipRootUpdated(_root, _ipfsCID, 1);

    vm.prank(_postman);
    registry.updateRoot(_root, _ipfsCID);

    assertEq(registry.roots(1), _root);
    assertEq(registry.currentRootIndex(), 1);
    assertEq(registry.latestMembershipRoot(), _root);

    uint256 _secondRoot = uint256(keccak256(abi.encodePacked(_root, uint8(69))));
    string memory _secondIpfsCID = "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG";

    vm.expectEmit(address(registry));
    emit IProofRegistry.MembershipRootUpdated(_secondRoot, _secondIpfsCID, 2);

    vm.prank(_postman);
    registry.updateRoot(_secondRoot, _secondIpfsCID);

    assertEq(registry.roots(2), _secondRoot);
    assertEq(registry.currentRootIndex(), 2);
    assertEq(registry.latestMembershipRoot(), _secondRoot);
  }

  function test_updateRootWhenNotPostman(address _notPostman, uint256 _root, string memory _ipfsCID) public {
    vm.expectRevert(IProofRegistry.OnlyPostman.selector);

    vm.prank(_notPostman);
    registry.updateRoot(_root, _ipfsCID);
  }

  function test_updateRootWhenEmptyRoot(address _postman, string memory _ipfsCID) public {
    vm.assume(bytes(_ipfsCID).length >= 32 && bytes(_ipfsCID).length <= 64);
    
    vm.prank(OWNER);
    registry.updatePostman(_postman, true);

    vm.expectRevert(IProofRegistry.InvalidRoot.selector);

    vm.prank(_postman);
    registry.updateRoot(uint256(0), _ipfsCID);
  }

  function test_updateRootWhenInvalidIPFSCIDLength(address _postman, uint256 _root, string memory _ipfsCID) public {
    vm.assume(_root != 0);
    // Test with CID that's too short or too long
    vm.assume(bytes(_ipfsCID).length < 32 || bytes(_ipfsCID).length > 64);
    
    vm.prank(OWNER);
    registry.updatePostman(_postman, true);

    vm.expectRevert(IProofRegistry.InvalidIPFSCIDLength.selector);

    vm.prank(_postman);
    registry.updateRoot(_root, _ipfsCID);
  }
}

contract UnitUpdatePostman is UnitProofRegistry {
  function test_enablePostmanHappyPath(address _postman) public {
    vm.prank(OWNER);

    vm.expectEmit(address(registry));
    emit IProofRegistry.PostmanUpdated(_postman, true);

    registry.updatePostman(_postman, true);

    assertTrue(registry.postmen(_postman));
  }

  function test_disablePostmanHappyPath(address _postman) public {
    vm.prank(OWNER);

    vm.expectEmit(address(registry));
    emit IProofRegistry.PostmanUpdated(_postman, false);

    registry.updatePostman(_postman, false);

    assertFalse(registry.postmen(_postman));
  }

  function test_udpatePostmanWhenNotOwner(address _caller, address _postman, bool _status) public {
    vm.assume(_caller != OWNER);

    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, _caller));

    vm.prank(_caller);
    registry.updatePostman(_postman, _status);
  }
}

contract UnitUpdateFees is UnitProofRegistry {
  function test_updateFeesHappyPath(uint256 _newFee) public {
    vm.prank(OWNER);

    vm.expectEmit(address(registry));
    emit IProofRegistry.FeeUpdated(FEE, _newFee);

    registry.updateFees(_newFee);

    assertEq(registry.feeBPS(), _newFee);
  }

  function test_updateFeesWhenNotOwner(address _caller, uint256 _newFee) public {
    vm.assume(_caller != OWNER);

    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, _caller));

    vm.prank(_caller);
    registry.updateFees(_newFee);
  }
}

contract UnitWithdrawFees is UnitProofRegistry {
  function test_withdrawFeesHappyPath(address _recipient, uint256 _balance) public {
    vm.deal(address(registry), _balance);

    vm.assume(_recipient != address(0));
    vm.deal(_recipient, 0);

    assumeNotPrecompile(_recipient);
    assumeNotForgeAddress(_recipient);
    vm.assume(_recipient != address(registry));
    vm.assume(_recipient != 0x000000000000000000000000000000000000000A);

    vm.expectEmit(address(registry));
    emit IProofRegistry.FeesWithdrawn(_recipient, _balance);

    vm.prank(OWNER);
    registry.withdrawFees(_recipient);

    assertEq(address(registry).balance, 0);
    assertEq(_recipient.balance, _balance);
  }

  function test_withdrawFeesWhenNotOwner(address _caller, address _recipient) public {
    vm.assume(_caller != OWNER);

    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, _caller));

    vm.prank(_caller);
    registry.withdrawFees(_recipient);
  }

  function test_withdrawFeesWhenNoRecipient(uint256 _balance) public {
    vm.deal(address(registry), _balance);

    vm.expectRevert(IProofRegistry.InvalidRecipient.selector);

    vm.prank(OWNER);
    registry.withdrawFees(address(0));
  }
}

contract UnitUpgrade is UnitProofRegistry {
  function test_upgradeHappyPath() public {
    ProofRegistry _newImpl = new ProofRegistry();

    vm.expectEmit(address(registry));
    emit IERC1967.Upgraded(address(_newImpl));

    vm.prank(OWNER);
    registry.upgradeToAndCall(address(_newImpl), "");
  }

  function test_upgradeWhenNotOwner(address _caller, bytes memory _data) public {
    vm.assume(_caller != OWNER);

    ProofRegistry _newImpl = new ProofRegistry();

    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, _caller));

    vm.prank(_caller);
    registry.upgradeToAndCall(address(_newImpl), _data);
  }
}

contract UnitSubmitMembershipProof is UnitProofRegistry {
  function test_submitMembershipProofHappyPath(
    address _caller,
    bytes memory _membershipProof,
    bytes32 _nullifierHash,
    uint256 _root
  ) public {
    registry.mockRoot(_root);

    _mockAndExpect(address(one_eth_pool), abi.encodeWithSelector(ITornado.denomination.selector), abi.encode(1 ether));

    uint256 _requiredFee = (1 ether * FEE) / 10_000;
    vm.deal(_caller, _requiredFee);

    _mockAndExpect(
      address(one_eth_pool), abi.encodeWithSelector(ITornado.nullifierHashes.selector, _nullifierHash), abi.encode(true)
    );

    _mockAndExpect(
      verifier,
      abi.encodeWithSelector(
        IVerifier.verifyProof.selector,
        _membershipProof,
        [registry.latestMembershipRoot(), uint256(_nullifierHash), 0, 0, 0, 0]
      ),
      abi.encode(true)
    );

    vm.expectEmit(address(registry));
    emit IProofRegistry.MembershipProofSubmitted(_caller, one_eth_pool, _nullifierHash, _requiredFee);

    vm.prank(_caller);
    registry.submitMembershipProof{value: _requiredFee}(one_eth_pool, _membershipProof, _nullifierHash);

    assertEq(registry.proofRegistry(uint256(_nullifierHash)), _root);
    assertEq(address(registry).balance, _requiredFee);
  }

  function test_submitMembershipProofWhenUnknownPool(
    address _caller,
    bytes memory _membershipProof,
    bytes32 _nullifierHash,
    ITornado _unknownPool
  ) public {
    vm.assume(_unknownPool != point_one_eth_pool);
    vm.assume(_unknownPool != one_eth_pool);
    vm.assume(_unknownPool != hundred_eth_pool);
    vm.assume(address(_unknownPool) != address(0));
    vm.assume(address(_unknownPool) != address(point_one_eth_pool));
    vm.assume(address(_unknownPool) != address(one_eth_pool));
    vm.assume(address(_unknownPool) != address(hundred_eth_pool));

    vm.expectRevert(IProofRegistry.UnknownPool.selector);

    vm.prank(_caller);
    registry.submitMembershipProof(_unknownPool, _membershipProof, _nullifierHash);
  }

  function test_submitMembershipProofWhenNullifierAlreadySubmitted(
    address _caller,
    bytes memory _membershipProof,
    bytes32 _nullifierHash
  ) public {
    registry.mockNullifierStatus(_nullifierHash, uint256(1));

    vm.expectRevert(IProofRegistry.ProofAlreadySubmittedForNullifierHash.selector);

    vm.prank(_caller);
    registry.submitMembershipProof(hundred_eth_pool, _membershipProof, _nullifierHash);
  }

  function test_submitMembershipProofWhenInsuffiecientFeePaid(
    address _caller,
    bytes memory _membershipProof,
    bytes32 _nullifierHash
  ) public {
    uint256 _requiredFee = (100 ether * FEE) / 10_000;
    vm.deal(_caller, _requiredFee);

    _mockAndExpect(
      address(hundred_eth_pool), abi.encodeWithSelector(ITornado.denomination.selector), abi.encode(100 ether)
    );

    vm.expectRevert(IProofRegistry.InsufficientFeePaid.selector);

    vm.prank(_caller);
    registry.submitMembershipProof{value: _requiredFee - 1}(hundred_eth_pool, _membershipProof, _nullifierHash);
  }

  function test_submitMembershipProofWhenNullifierUnspent(
    address _caller,
    bytes memory _membershipProof,
    bytes32 _nullifierHash
  ) public {
    _mockAndExpect(address(one_eth_pool), abi.encodeWithSelector(ITornado.denomination.selector), abi.encode(1 ether));

    uint256 _requiredFee = (1 ether * FEE) / 10_000;
    vm.deal(_caller, _requiredFee);

    _mockAndExpect(
      address(one_eth_pool),
      abi.encodeWithSelector(ITornado.nullifierHashes.selector, _nullifierHash),
      abi.encode(false)
    );

    vm.expectRevert(IProofRegistry.NullifierHashUnspent.selector);

    vm.prank(_caller);
    registry.submitMembershipProof{value: _requiredFee}(one_eth_pool, _membershipProof, _nullifierHash);
  }

  function test_submitMembershipProofWhenInvalidMembershipProof(
    address _caller,
    bytes memory _membershipProof,
    bytes32 _nullifierHash
  ) public {
    _mockAndExpect(
      address(hundred_eth_pool), abi.encodeWithSelector(ITornado.denomination.selector), abi.encode(100 ether)
    );

    uint256 _requiredFee = (100 ether * FEE) / 10_000;
    vm.deal(_caller, _requiredFee);

    _mockAndExpect(
      address(hundred_eth_pool),
      abi.encodeWithSelector(ITornado.nullifierHashes.selector, _nullifierHash),
      abi.encode(true)
    );

    _mockAndExpect(
      verifier,
      abi.encodeWithSelector(
        IVerifier.verifyProof.selector,
        _membershipProof,
        [registry.latestMembershipRoot(), uint256(_nullifierHash), 0, 0, 0, 0]
      ),
      abi.encode(false)
    );

    vm.expectRevert(IProofRegistry.InvalidMembershipProof.selector);

    vm.prank(_caller);
    registry.submitMembershipProof{value: _requiredFee}(hundred_eth_pool, _membershipProof, _nullifierHash);
  }
}

contract UnitWithdrawAndSubmitProof is UnitProofRegistry {
  function test_withdrawAndSubmitProofWhenUnknownPool(
    bytes memory _membershipProof,
    bytes memory _withdrawProof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address _recipient,
    address _relayer,
    uint256 _fee,
    uint256 _refund,
    ITornado _unknownPool
  ) public {
    vm.assume(address(_unknownPool) != address(0));
    vm.assume(address(_unknownPool) != address(point_one_eth_pool));
    vm.assume(address(_unknownPool) != address(one_eth_pool));
    vm.assume(address(_unknownPool) != address(hundred_eth_pool));
    vm.assume(uint160(address(_unknownPool)) > 0x1000); // Avoid precompiles

    vm.expectRevert(IProofRegistry.UnknownPool.selector);

    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      _recipient,
      _relayer,
      _fee,
      _refund,
      _unknownPool
    );
  }

  function test_withdrawAndSubmitProofBasicFlow(
    bytes memory _membershipProof,
    bytes memory _withdrawProof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address _recipient,
    address _relayer,
    uint256 _fee,
    uint256 _refund,
    uint256 _membershipRoot
  ) public {
    registry.mockRoot(_membershipRoot);
    
    // Mock verifier to return false to trigger InvalidMembershipProof early
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(false));
    
    vm.expectRevert(IProofRegistry.InvalidMembershipProof.selector);
    registry.withdrawAndPostMembershipProof(_membershipProof, _withdrawProof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, one_eth_pool);
  }

  function test_withdrawAndSubmitProofWithValidMockButInvalidAmount(
    bytes memory _membershipProof,
    bytes memory _withdrawProof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address _recipient,
    address _relayer,
    uint256 _membershipRoot
  ) public {
    registry.mockRoot(_membershipRoot);
    
    // Mock verifier to return true but don't simulate proper balance change
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(true));
    vm.mockCall(address(one_eth_pool), abi.encodeWithSelector(ITornado.denomination.selector), abi.encode(1 ether));
    vm.mockCall(address(one_eth_pool), abi.encodeWithSelector(ITornado.withdraw.selector), abi.encode());
    
    // Use fixed values that will definitely cause the test to revert with InvalidWithdrawnAmount
    // since we're not actually depositing any ETH to the contract
    vm.expectRevert(IProofRegistry.InvalidWithdrawnAmount.selector);
    registry.withdrawAndPostMembershipProof(_membershipProof, _withdrawProof, _root, _nullifierHash, _recipient, _relayer, 0.5 ether, 0, one_eth_pool);
  }

  function test_withdrawAndSubmitProofSuccessfulFlow() public {
    // Setup test parameters
    bytes memory _membershipProof = hex"1234";
    bytes memory _withdrawProof = hex"5678";
    bytes32 _root = bytes32(uint256(1));
    bytes32 _nullifierHash = bytes32(uint256(2));
    address _recipient = makeAddr("recipient");
    address _relayer = makeAddr("relayer");
    uint256 _fee = 0.05 ether;
    uint256 _refund = 0;
    uint256 _membershipRoot = uint256(3);
    
    // Deploy mock pool
    MockTornadoPool mockPool = new MockTornadoPool();
    vm.deal(address(mockPool), 10 ether);
    
    // Setup initial state
    registry.mockRoot(_membershipRoot);
    registry.mockKnownPool(ITornado(address(mockPool)));
    
    // Ensure nullifier is not registered initially
    assertEq(registry.proofRegistry(uint256(_nullifierHash)), 0);
    
    // Mock verifier
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(true));
    
    // Call withdrawAndPostMembershipProof
    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      _recipient,
      _relayer,
      _fee,
      _refund,
      ITornado(address(mockPool))
    );
    
    // Verify nullifier was registered with the current membership root
    assertEq(registry.proofRegistry(uint256(_nullifierHash)), _membershipRoot);
    
    // Calculate expected amounts
    uint256 withdrawnAmount = 1 ether - _fee;
    uint256 expectedRecipientAmount = (withdrawnAmount * (10_000 - FEE)) / 10_000;
    uint256 expectedFees = (withdrawnAmount * FEE) / 10_000;
    
    // Verify recipient received funds minus fees
    assertEq(_recipient.balance, expectedRecipientAmount);
    
    // Verify registry kept the fees
    assertEq(address(registry).balance, expectedFees);
  }

  function test_withdrawAndSubmitProofCannotReuseNullifier() public {
    // Setup test parameters
    bytes memory _membershipProof = hex"1234";
    bytes memory _withdrawProof = hex"5678";
    bytes32 _root = bytes32(uint256(1));
    bytes32 _nullifierHash = bytes32(uint256(2));
    address _recipient = makeAddr("recipient");
    address _relayer = makeAddr("relayer");
    uint256 _fee = 0.05 ether;
    uint256 _refund = 0;
    uint256 _membershipRoot = uint256(3);
    
    // Deploy mock pool
    MockTornadoPool mockPool = new MockTornadoPool();
    vm.deal(address(mockPool), 10 ether);
    
    // Setup initial state
    registry.mockRoot(_membershipRoot);
    registry.mockKnownPool(ITornado(address(mockPool)));
    
    // Mock verifier
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(true));
    
    // First successful withdrawal
    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      _recipient,
      _relayer,
      _fee,
      _refund,
      ITornado(address(mockPool))
    );
    
    // Verify the nullifier was registered
    assertEq(registry.proofRegistry(uint256(_nullifierHash)), _membershipRoot);
    
    // Attempt to reuse the same nullifier should fail
    vm.expectRevert(IProofRegistry.ProofAlreadySubmittedForNullifierHash.selector);
    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      _recipient,
      _relayer,
      _fee,
      _refund,
      ITornado(address(mockPool))
    );
  }

  function test_withdrawAndSubmitProofFailedTransfer() public {
    // Setup test parameters
    bytes memory _membershipProof = hex"1234";
    bytes memory _withdrawProof = hex"5678";
    bytes32 _root = bytes32(uint256(1));
    bytes32 _nullifierHash = bytes32(uint256(2));
    address _relayer = makeAddr("relayer");
    uint256 _fee = 0.05 ether;
    uint256 _refund = 0;
    uint256 _membershipRoot = uint256(3);
    
    // Deploy mock pool
    MockTornadoPool mockPool = new MockTornadoPool();
    vm.deal(address(mockPool), 10 ether);
    
    // Deploy a contract that rejects ETH transfers
    RejectETH recipient = new RejectETH();
    
    // Setup initial state
    registry.mockRoot(_membershipRoot);
    registry.mockKnownPool(ITornado(address(mockPool)));
    
    // Mock verifier
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(true));
    
    // Expect revert when transfer fails
    vm.expectRevert(IProofRegistry.FailedToSendETH.selector);
    
    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      address(recipient),
      _relayer,
      _fee,
      _refund,
      ITornado(address(mockPool))
    );
  }

  function test_withdrawAndSubmitProofZeroRecipient() public {
    // Setup test parameters
    bytes memory _membershipProof = hex"1234";
    bytes memory _withdrawProof = hex"5678";
    bytes32 _root = bytes32(uint256(1));
    bytes32 _nullifierHash = bytes32(uint256(2));
    address _relayer = makeAddr("relayer");
    uint256 _fee = 0.05 ether;
    uint256 _refund = 0;
    uint256 _membershipRoot = uint256(3);
    
    // Deploy mock pool
    MockTornadoPool mockPool = new MockTornadoPool();
    vm.deal(address(mockPool), 10 ether);
    
    // Setup initial state
    registry.mockRoot(_membershipRoot);
    registry.mockKnownPool(ITornado(address(mockPool)));
    
    // Mock verifier
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(true));
    
    // Expect revert for zero address recipient
    vm.expectRevert(IProofRegistry.InvalidRecipient.selector);
    
    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      address(0),
      _relayer,
      _fee,
      _refund,
      ITornado(address(mockPool))
    );
  }

  function test_withdrawAndSubmitProofWithRefund() public {
    // Setup test parameters
    bytes memory _membershipProof = hex"1234";
    bytes memory _withdrawProof = hex"5678";
    bytes32 _root = bytes32(uint256(1));
    bytes32 _nullifierHash = bytes32(uint256(2));
    address _recipient = makeAddr("recipient");
    address _relayer = makeAddr("relayer");
    uint256 _fee = 0.05 ether;
    uint256 _refund = 0.01 ether;
    uint256 _membershipRoot = uint256(3);
    
    // Deploy mock pool
    MockTornadoPool mockPool = new MockTornadoPool();
    vm.deal(address(mockPool), 10 ether);
    
    // Setup initial state
    registry.mockRoot(_membershipRoot);
    registry.mockKnownPool(ITornado(address(mockPool)));
    
    // Mock verifier
    vm.mockCall(verifier, abi.encodeWithSelector(IVerifier.verifyProof.selector), abi.encode(true));
    
    registry.withdrawAndPostMembershipProof(
      _membershipProof,
      _withdrawProof,
      _root,
      _nullifierHash,
      _recipient,
      _relayer,
      _fee,
      _refund,
      ITornado(address(mockPool))
    );
    
    // Verify the nullifier was registered
    assertEq(registry.proofRegistry(uint256(_nullifierHash)), _membershipRoot);
    
    // Calculate expected amounts
    uint256 withdrawnAmount = 1 ether - _fee;
    uint256 expectedRecipientAmount = (withdrawnAmount * (10_000 - FEE)) / 10_000;
    uint256 expectedFees = withdrawnAmount - expectedRecipientAmount;
    
    // Verify recipient received funds minus fees
    assertEq(_recipient.balance, expectedRecipientAmount);
    
    // Verify registry kept the fees
    assertEq(address(registry).balance, expectedFees);
  }
}

contract RejectETH {
  receive() external payable {
    revert("Reject ETH");
  }
}

contract MockTornadoPool {
  uint256 public denomination = 1 ether;
  
  function withdraw(
    bytes calldata,
    bytes32,
    bytes32,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256
  ) external {
    // Send denomination - fee to recipient
    uint256 toSend = denomination - _fee;
    (bool success,) = _recipient.call{value: toSend}("");
    require(success, "Transfer failed");
  }
  
  receive() external payable {}
}

contract UnitReceiveFunction is UnitProofRegistry {
  function test_receiveETH(uint256 _amount) public {
    vm.deal(address(this), _amount);
    
    uint256 _balanceBefore = address(registry).balance;
    
    (bool _success,) = address(registry).call{value: _amount}("");
    assertTrue(_success);
    
    assertEq(address(registry).balance, _balanceBefore + _amount);
  }
}
