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
  function test_updateRootHappyPath(address _postman, uint256 _root, bytes32 _ipfsHash) public {
    vm.assume(_root != 0);
    vm.assume(_ipfsHash != 0);

    vm.prank(OWNER);
    registry.updatePostman(_postman, true);

    vm.expectEmit(address(registry));
    emit IProofRegistry.MembershipRootUpdated(_root, _ipfsHash, 1);

    vm.prank(_postman);
    registry.updateRoot(_root, _ipfsHash);

    assertEq(registry.roots(1), _root);
    assertEq(registry.currentRootIndex(), 1);
    assertEq(registry.latestMembershipRoot(), _root);

    uint256 _secondRoot = uint256(keccak256(abi.encodePacked(_root, uint8(69))));
    bytes32 _secondIpfsHash = keccak256(abi.encodePacked(_ipfsHash, uint8(69)));

    vm.expectEmit(address(registry));
    emit IProofRegistry.MembershipRootUpdated(_secondRoot, _secondIpfsHash, 2);

    vm.prank(_postman);
    registry.updateRoot(_secondRoot, _secondIpfsHash);

    assertEq(registry.roots(2), _secondRoot);
    assertEq(registry.currentRootIndex(), 2);
    assertEq(registry.latestMembershipRoot(), _secondRoot);
  }

  function test_updateRootWhenNotPostman(address _notPostman, uint256 _root, bytes32 _ipfsHash) public {
    vm.expectRevert(IProofRegistry.OnlyPostman.selector);

    vm.prank(_notPostman);
    registry.updateRoot(_root, _ipfsHash);
  }

  function test_updateRootWhenEmptyRoot(address _postman, bytes32 _ipfsHash) public {
    vm.prank(OWNER);
    registry.updatePostman(_postman, true);

    vm.expectRevert(IProofRegistry.InvalidRootOrIPFSHash.selector);

    vm.prank(_postman);
    registry.updateRoot(uint256(0), _ipfsHash);
  }

  function test_updateRootWhenEmptyIPFSHash(address _postman, uint256 _root) public {
    vm.prank(OWNER);
    registry.updatePostman(_postman, true);

    vm.expectRevert(IProofRegistry.InvalidRootOrIPFSHash.selector);

    vm.prank(_postman);
    registry.updateRoot(_root, bytes32(0));
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
    registry.upgradeToAndCall(address(_newImpl), '');
  }

  function test_upgradeWhenNotOwner(address _caller) public {
    vm.assume(_caller != OWNER);

    ProofRegistry _newImpl = new ProofRegistry();

    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, _caller));

    vm.prank(_caller);
    registry.upgradeToAndCall(address(_newImpl), '');
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
  function test_withdrawAndSubmitProofHappyPath(
    bytes memory _membershipProof,
    bytes memory _withdrawProof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address _recipient,
    address _relayer,
    uint256 _fee,
    uint256 _refund,
    uint256 _membershipRoot,
    address _caller
  ) public {
    vm.skip(true);

    registry.mockRoot(_membershipRoot);
    _fee = bound(_fee, 0.1 ether, 0.2 ether);

    uint256 _withdrawProofHash = uint256(
      keccak256(
        abi.encodePacked(
          one_eth_pool, _withdrawProof, _root, _nullifierHash, address(registry), _relayer, _fee, _refund
        )
      )
    ) % _SNARK_SCALAR_FIELD;

    _mockAndExpect(
      verifier,
      abi.encodeWithSelector(
        IVerifier.verifyProof.selector,
        _membershipProof,
        [
          registry.latestMembershipRoot(),
          uint256(_nullifierHash),
          uint256(uint160(_recipient)),
          _withdrawProofHash,
          0,
          0
        ]
      ),
      abi.encode(true)
    );

    _mockAndExpect(
      address(one_eth_pool),
      abi.encodeWithSelector(
        ITornado.withdraw.selector,
        _withdrawProofHash,
        _root,
        _nullifierHash,
        payable(address(registry)),
        payable(_relayer),
        _fee,
        _refund
      ),
      abi.encode()
    );

    _mockAndExpect(address(one_eth_pool), abi.encodeWithSelector(ITornado.denomination.selector), abi.encode(1 ether));

    vm.prank(_caller);
    registry.withdrawAndPostMembershipProof(
      _membershipProof, _withdrawProof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, one_eth_pool
    );
  }
}
