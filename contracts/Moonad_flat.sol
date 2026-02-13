// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/pyth-crosschain/target_chains/ethereum/entropy_sdk/solidity/EntropyStructs.sol

// This contract holds old versions of the Entropy structs that are no longer used for contract storage.
// However, they are still used in EntropyEvents to maintain the public interface of prior versions of
// the Entropy contract.
//
// See EntropyStructsV2 for the struct definitions currently in use.
contract EntropyStructs {
    struct ProviderInfo {
        uint128 feeInWei;
        uint128 accruedFeesInWei;
        // The commitment that the provider posted to the blockchain, and the sequence number
        // where they committed to this. This value is not advanced after the provider commits,
        // and instead is stored to help providers track where they are in the hash chain.
        bytes32 originalCommitment;
        uint64 originalCommitmentSequenceNumber;
        // Metadata for the current commitment. Providers may optionally use this field to help
        // manage rotations (i.e., to pick the sequence number from the correct hash chain).
        bytes commitmentMetadata;
        // Optional URI where clients can retrieve revelations for the provider.
        // Client SDKs can use this field to automatically determine how to retrieve random values for each provider.
        // TODO: specify the API that must be implemented at this URI
        bytes uri;
        // The first sequence number that is *not* included in the current commitment (i.e., an exclusive end index).
        // The contract maintains the invariant that sequenceNumber <= endSequenceNumber.
        // If sequenceNumber == endSequenceNumber, the provider must rotate their commitment to add additional random values.
        uint64 endSequenceNumber;
        // The sequence number that will be assigned to the next inbound user request.
        uint64 sequenceNumber;
        // The current commitment represents an index/value in the provider's hash chain.
        // These values are used to verify requests for future sequence numbers. Note that
        // currentCommitmentSequenceNumber < sequenceNumber.
        //
        // The currentCommitment advances forward through the provider's hash chain as values
        // are revealed on-chain.
        bytes32 currentCommitment;
        uint64 currentCommitmentSequenceNumber;
        // An address that is authorized to set / withdraw fees on behalf of this provider.
        address feeManager;
        // Maximum number of hashes to record in a request. This should be set according to the maximum gas limit
        // the provider supports for callbacks.
        uint32 maxNumHashes;
    }

    struct Request {
        // Storage slot 1 //
        address provider;
        uint64 sequenceNumber;
        // The number of hashes required to verify the provider revelation.
        uint32 numHashes;
        // Storage slot 2 //
        // The commitment is keccak256(userCommitment, providerCommitment). Storing the hash instead of both saves 20k gas by
        // eliminating 1 store.
        bytes32 commitment;
        // Storage slot 3 //
        // The number of the block where this request was created.
        // Note that we're using a uint64 such that we have an additional space for an address and other fields in
        // this storage slot. Although block.number returns a uint256, 64 bits should be plenty to index all of the
        // blocks ever generated.
        uint64 blockNumber;
        // The address that requested this random number.
        address requester;
        // If true, incorporate the blockhash of blockNumber into the generated random value.
        bool useBlockhash;
        // True if this is a request that expects a callback.
        bool isRequestWithCallback;
    }
}

// lib/pyth-crosschain/target_chains/ethereum/entropy_sdk/solidity/EntropyStructsV2.sol

contract EntropyStructsV2 {
    struct ProviderInfo {
        uint128 feeInWei;
        uint128 accruedFeesInWei;
        // The commitment that the provider posted to the blockchain, and the sequence number
        // where they committed to this. This value is not advanced after the provider commits,
        // and instead is stored to help providers track where they are in the hash chain.
        bytes32 originalCommitment;
        uint64 originalCommitmentSequenceNumber;
        // Metadata for the current commitment. Providers may optionally use this field to help
        // manage rotations (i.e., to pick the sequence number from the correct hash chain).
        bytes commitmentMetadata;
        // Optional URI where clients can retrieve revelations for the provider.
        // Client SDKs can use this field to automatically determine how to retrieve random values for each provider.
        // TODO: specify the API that must be implemented at this URI
        bytes uri;
        // The first sequence number that is *not* included in the current commitment (i.e., an exclusive end index).
        // The contract maintains the invariant that sequenceNumber <= endSequenceNumber.
        // If sequenceNumber == endSequenceNumber, the provider must rotate their commitment to add additional random values.
        uint64 endSequenceNumber;
        // The sequence number that will be assigned to the next inbound user request.
        uint64 sequenceNumber;
        // The current commitment represents an index/value in the provider's hash chain.
        // These values are used to verify requests for future sequence numbers. Note that
        // currentCommitmentSequenceNumber < sequenceNumber.
        //
        // The currentCommitment advances forward through the provider's hash chain as values
        // are revealed on-chain.
        bytes32 currentCommitment;
        uint64 currentCommitmentSequenceNumber;
        // An address that is authorized to set / withdraw fees on behalf of this provider.
        address feeManager;
        // Maximum number of hashes to record in a request. This should be set according to the maximum gas limit
        // the provider supports for callbacks.
        uint32 maxNumHashes;
        // Default gas limit to use for callbacks.
        uint32 defaultGasLimit;
    }

    struct Request {
        // Storage slot 1 //
        address provider;
        uint64 sequenceNumber;
        // The number of hashes required to verify the provider revelation.
        uint32 numHashes;
        // Storage slot 2 //
        // The commitment is keccak256(userCommitment, providerCommitment). Storing the hash instead of both saves 20k gas by
        // eliminating 1 store.
        bytes32 commitment;
        // Storage slot 3 //
        // The number of the block where this request was created.
        // Note that we're using a uint64 such that we have an additional space for an address and other fields in
        // this storage slot. Although block.number returns a uint256, 64 bits should be plenty to index all of the
        // blocks ever generated.
        uint64 blockNumber;
        // The address that requested this random number.
        address requester;
        // If true, incorporate the blockhash of blockNumber into the generated random value.
        bool useBlockhash;
        // Status flag for requests with callbacks. See EntropyConstants for the possible values of this flag.
        uint8 callbackStatus;
        // The gasLimit in units of 10k gas. (i.e., 2 = 20k gas). We're using units of 10k in order to fit this
        // field into the remaining 2 bytes of this storage slot. The dynamic range here is 10k - 655M, which should
        // cover all real-world use cases.
        uint16 gasLimit10k;
    }
}

// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/pyth-crosschain/target_chains/ethereum/entropy_sdk/solidity/IEntropyConsumer.sol

abstract contract IEntropyConsumer {
    // This method is called by Entropy to provide the random number to the consumer.
    // It asserts that the msg.sender is the Entropy contract. It is not meant to be
    // override by the consumer.
    function _entropyCallback(
        uint64 sequence,
        address provider,
        bytes32 randomNumber
    ) external {
        address entropy = getEntropy();
        require(entropy != address(0), "Entropy address not set");
        require(msg.sender == entropy, "Only Entropy can call this function");

        entropyCallback(sequence, provider, randomNumber);
    }

    // getEntropy returns Entropy contract address. The method is being used to check that the
    // callback is indeed from Entropy contract. The consumer is expected to implement this method.
    // Entropy address can be found here - https://docs.pyth.network/entropy/contract-addresses
    function getEntropy() internal view virtual returns (address);

    // This method is expected to be implemented by the consumer to handle the random number.
    // It will be called by _entropyCallback after _entropyCallback ensures that the call is
    // indeed from Entropy contract.
    function entropyCallback(
        uint64 sequence,
        address provider,
        bytes32 randomNumber
    ) internal virtual;
}

// lib/openzeppelin-contracts/contracts/utils/StorageSlot.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC-1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * TIP: Consider using this library along with {SlotDerivation}.
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct Int256Slot {
        int256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `Int256Slot` with member `value` located at `slot`.
     */
    function getInt256Slot(bytes32 slot) internal pure returns (Int256Slot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns a `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns a `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        assembly ("memory-safe") {
            r.slot := store.slot
        }
    }
}

// lib/pyth-crosschain/target_chains/ethereum/entropy_sdk/solidity/EntropyEvents.sol

// Deprecated -- these events are still emitted, but the lack of indexing
// makes them hard to use.
interface EntropyEvents {
    event Registered(EntropyStructs.ProviderInfo provider);

    event Requested(EntropyStructs.Request request);
    event RequestedWithCallback(
        address indexed provider,
        address indexed requestor,
        uint64 indexed sequenceNumber,
        bytes32 userRandomNumber,
        EntropyStructs.Request request
    );

    event Revealed(
        EntropyStructs.Request request,
        bytes32 userRevelation,
        bytes32 providerRevelation,
        bytes32 blockHash,
        bytes32 randomNumber
    );
    event RevealedWithCallback(
        EntropyStructs.Request request,
        bytes32 userRandomNumber,
        bytes32 providerRevelation,
        bytes32 randomNumber
    );

    event CallbackFailed(
        address indexed provider,
        address indexed requestor,
        uint64 indexed sequenceNumber,
        bytes32 userRandomNumber,
        bytes32 providerRevelation,
        bytes32 randomNumber,
        bytes errorCode
    );

    event ProviderFeeUpdated(address provider, uint128 oldFee, uint128 newFee);

    event ProviderDefaultGasLimitUpdated(
        address indexed provider,
        uint32 oldDefaultGasLimit,
        uint32 newDefaultGasLimit
    );

    event ProviderUriUpdated(address provider, bytes oldUri, bytes newUri);

    event ProviderFeeManagerUpdated(
        address provider,
        address oldFeeManager,
        address newFeeManager
    );
    event ProviderMaxNumHashesAdvanced(
        address provider,
        uint32 oldMaxNumHashes,
        uint32 newMaxNumHashes
    );

    event Withdrawal(
        address provider,
        address recipient,
        uint128 withdrawnAmount
    );
}

// lib/pyth-crosschain/target_chains/ethereum/entropy_sdk/solidity/EntropyEventsV2.sol

/**
 * @title EntropyEventsV2
 * @notice Interface defining events for the Entropy V2 system, which handles random number generation
 * and provider management on Ethereum.
 * @dev This interface is used to emit events that track the lifecycle of random number requests,
 * provider registrations, and system configurations.
 */
interface EntropyEventsV2 {
    /**
     * @notice Emitted when a new provider registers with the Entropy system
     * @param provider The address of the registered provider
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event Registered(address indexed provider, bytes extraArgs);

    /**
     * @notice Emitted when a user requests a random number from a provider
     * @param provider The address of the provider handling the request
     * @param caller The address of the user requesting the random number
     * @param sequenceNumber A unique identifier for this request
     * @param userContribution The user's contribution to the random number
     * @param gasLimit The gas limit for the callback.
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event Requested(
        address indexed provider,
        address indexed caller,
        uint64 indexed sequenceNumber,
        bytes32 userContribution,
        uint32 gasLimit,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider reveals the generated random number
     * @param provider The address of the provider that generated the random number
     * @param caller The address of the user who requested the random number (and who receives a callback)
     * @param sequenceNumber The unique identifier of the request
     * @param randomNumber The generated random number
     * @param userContribution The user's contribution to the random number
     * @param providerContribution The provider's contribution to the random number
     * @param callbackFailed Whether the callback to the caller failed
     * @param callbackReturnValue Return value from the callback. If the callback failed, this field contains
     * the error code and any additional returned data. Note that "" often indicates an out-of-gas error.
     * If the callback returns more than 256 bytes, only the first 256 bytes of the callback return value are included.
     * @param callbackGasUsed How much gas the callback used.
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event Revealed(
        address indexed provider,
        address indexed caller,
        uint64 indexed sequenceNumber,
        bytes32 randomNumber,
        bytes32 userContribution,
        bytes32 providerContribution,
        bool callbackFailed,
        bytes callbackReturnValue,
        uint32 callbackGasUsed,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider updates their fee
     * @param provider The address of the provider updating their fee
     * @param oldFee The previous fee amount
     * @param newFee The new fee amount
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event ProviderFeeUpdated(
        address indexed provider,
        uint128 oldFee,
        uint128 newFee,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider updates their default gas limit
     * @param provider The address of the provider updating their gas limit
     * @param oldDefaultGasLimit The previous default gas limit
     * @param newDefaultGasLimit The new default gas limit
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event ProviderDefaultGasLimitUpdated(
        address indexed provider,
        uint32 oldDefaultGasLimit,
        uint32 newDefaultGasLimit,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider updates their URI
     * @param provider The address of the provider updating their URI
     * @param oldUri The previous URI
     * @param newUri The new URI
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event ProviderUriUpdated(
        address indexed provider,
        bytes oldUri,
        bytes newUri,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider updates their fee manager address
     * @param provider The address of the provider updating their fee manager
     * @param oldFeeManager The previous fee manager address
     * @param newFeeManager The new fee manager address
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event ProviderFeeManagerUpdated(
        address indexed provider,
        address oldFeeManager,
        address newFeeManager,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider updates their maximum number of hashes that can be advanced
     * @param provider The address of the provider updating their max hashes
     * @param oldMaxNumHashes The previous maximum number of hashes
     * @param newMaxNumHashes The new maximum number of hashes
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event ProviderMaxNumHashesAdvanced(
        address indexed provider,
        uint32 oldMaxNumHashes,
        uint32 newMaxNumHashes,
        bytes extraArgs
    );

    /**
     * @notice Emitted when a provider withdraws their accumulated fees
     * @param provider The address of the provider withdrawing fees
     * @param recipient The address receiving the withdrawn fees
     * @param withdrawnAmount The amount of fees withdrawn
     * @param extraArgs A field for extra data for forward compatibility.
     */
    event Withdrawal(
        address indexed provider,
        address indexed recipient,
        uint128 withdrawnAmount,
        bytes extraArgs
    );
}

// lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

// lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.5.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * IMPORTANT: Deprecated. This storage-based reentrancy guard will be removed and replaced
 * by the {ReentrancyGuardTransient} variant in v6.0.
 *
 * @custom:stateless
 */
abstract contract ReentrancyGuard {
    using StorageSlot for bytes32;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant REENTRANCY_GUARD_STORAGE =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev A `view` only version of {nonReentrant}. Use to block view functions
     * from being called, preventing reading from inconsistent contract state.
     *
     * CAUTION: This is a "view" modifier and does not change the reentrancy
     * status. Use it only on view functions. For payable or non-payable functions,
     * use the standard {nonReentrant} modifier instead.
     */
    modifier nonReentrantView() {
        _nonReentrantBeforeView();
        _;
    }

    function _nonReentrantBeforeView() private view {
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        _nonReentrantBeforeView();

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorageSlot().getUint256Slot().value = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorageSlot().getUint256Slot().value = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyGuardStorageSlot().getUint256Slot().value == ENTERED;
    }

    function _reentrancyGuardStorageSlot() internal pure virtual returns (bytes32) {
        return REENTRANCY_GUARD_STORAGE;
    }
}

// lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// lib/pyth-crosschain/target_chains/ethereum/entropy_sdk/solidity/IEntropyV2.sol

interface IEntropyV2 is EntropyEventsV2 {
    /// @notice Request a random number using the default provider with default gas limit
    /// @return assignedSequenceNumber A unique identifier for this request
    /// @dev The address calling this function should be a contract that inherits from the IEntropyConsumer interface.
    /// The `entropyCallback` method on that interface will receive a callback with the returned sequence number and
    /// the generated random number.
    ///
    /// `entropyCallback` will be run with the provider's configured default gas limit.
    ///
    /// This method will revert unless the caller provides a sufficient fee (at least `getFeeV2()`) as msg.value.
    /// Note that the fee can change over time. Callers of this method should explicitly compute `getFeeV2()`
    /// prior to each invocation (as opposed to hardcoding a value). Further note that excess value is *not* refunded to the caller.
    ///
    /// Note that this method uses an in-contract PRNG to generate the user's contribution to the random number.
    /// This approach modifies the security guarantees such that a dishonest validator and provider can
    /// collude to manipulate the result (as opposed to a malicious user and provider). That is, the user
    /// now trusts the validator honestly draw a random number. If you wish to avoid this trust assumption,
    /// call a variant of `requestV2` that accepts a `userRandomNumber` parameter.
    function requestV2()
        external
        payable
        returns (uint64 assignedSequenceNumber);

    /// @notice Request a random number using the default provider with specified gas limit
    /// @param gasLimit The gas limit for the callback function.
    /// @return assignedSequenceNumber A unique identifier for this request
    /// @dev The address calling this function should be a contract that inherits from the IEntropyConsumer interface.
    /// The `entropyCallback` method on that interface will receive a callback with the returned sequence number and
    /// the generated random number.
    ///
    /// `entropyCallback` will be run with the `gasLimit` provided to this function.
    /// The `gasLimit` will be rounded up to a multiple of 10k (e.g., 19000 -> 20000), and furthermore is lower bounded
    /// by the provider's configured default limit.
    ///
    /// This method will revert unless the caller provides a sufficient fee (at least `getFeeV2(gasLimit)`) as msg.value.
    /// Note that the fee can change over time. Callers of this method should explicitly compute `getFeeV2(gasLimit)`
    /// prior to each invocation (as opposed to hardcoding a value). Further note that excess value is *not* refunded to the caller.
    ///
    /// Note that this method uses an in-contract PRNG to generate the user's contribution to the random number.
    /// This approach modifies the security guarantees such that a dishonest validator and provider can
    /// collude to manipulate the result (as opposed to a malicious user and provider). That is, the user
    /// now trusts the validator honestly draw a random number. If you wish to avoid this trust assumption,
    /// call a variant of `requestV2` that accepts a `userRandomNumber` parameter.
    function requestV2(
        uint32 gasLimit
    ) external payable returns (uint64 assignedSequenceNumber);

    /// @notice Request a random number from a specific provider with specified gas limit
    /// @param provider The address of the provider to request from
    /// @param gasLimit The gas limit for the callback function
    /// @return assignedSequenceNumber A unique identifier for this request
    /// @dev The address calling this function should be a contract that inherits from the IEntropyConsumer interface.
    /// The `entropyCallback` method on that interface will receive a callback with the returned sequence number and
    /// the generated random number.
    ///
    /// `entropyCallback` will be run with the `gasLimit` provided to this function.
    /// The `gasLimit` will be rounded up to a multiple of 10k (e.g., 19000 -> 20000), and furthermore is lower bounded
    /// by the provider's configured default limit.
    ///
    /// This method will revert unless the caller provides a sufficient fee (at least `getFeeV2(provider, gasLimit)`) as msg.value.
    /// Note that provider fees can change over time. Callers of this method should explicitly compute `getFeeV2(provider, gasLimit)`
    /// prior to each invocation (as opposed to hardcoding a value). Further note that excess value is *not* refunded to the caller.
    ///
    /// Note that this method uses an in-contract PRNG to generate the user's contribution to the random number.
    /// This approach modifies the security guarantees such that a dishonest validator and provider can
    /// collude to manipulate the result (as opposed to a malicious user and provider). That is, the user
    /// now trusts the validator honestly draw a random number. If you wish to avoid this trust assumption,
    /// call a variant of `requestV2` that accepts a `userRandomNumber` parameter.
    function requestV2(
        address provider,
        uint32 gasLimit
    ) external payable returns (uint64 assignedSequenceNumber);

    /// @notice Request a random number from a specific provider with a user-provided random number and gas limit
    /// @param provider The address of the provider to request from
    /// @param userRandomNumber A random number provided by the user for additional entropy
    /// @param gasLimit The gas limit for the callback function. Pass 0 to get a sane default value -- see note below.
    /// @return assignedSequenceNumber A unique identifier for this request
    /// @dev The address calling this function should be a contract that inherits from the IEntropyConsumer interface.
    /// The `entropyCallback` method on that interface will receive a callback with the returned sequence number and
    /// the generated random number.
    ///
    /// `entropyCallback` will be run with the `gasLimit` provided to this function.
    /// The `gasLimit` will be rounded up to a multiple of 10k (e.g., 19000 -> 20000), and furthermore is lower bounded
    /// by the provider's configured default limit.
    ///
    /// This method will revert unless the caller provides a sufficient fee (at least `getFeeV2(provider, gasLimit)`) as msg.value.
    /// Note that provider fees can change over time. Callers of this method should explicitly compute `getFeeV2(provider, gasLimit)`
    /// prior to each invocation (as opposed to hardcoding a value). Further note that excess value is *not* refunded to the caller.
    function requestV2(
        address provider,
        bytes32 userRandomNumber,
        uint32 gasLimit
    ) external payable returns (uint64 assignedSequenceNumber);

    /// @notice Get information about a specific entropy provider
    /// @param provider The address of the provider to query
    /// @return info The provider information including configuration, fees, and operational status
    /// @dev This method returns detailed information about a provider's configuration and capabilities.
    /// The returned ProviderInfo struct contains information such as the provider's fee structure and gas limits.
    function getProviderInfoV2(
        address provider
    ) external view returns (EntropyStructsV2.ProviderInfo memory info);

    /// @notice Get the address of the default entropy provider
    /// @return provider The address of the default provider
    /// @dev This method returns the address of the provider that will be used when no specific provider is specified
    /// in the requestV2 calls. The default provider can be used to get the base fee and gas limit information.
    function getDefaultProvider() external view returns (address provider);

    /// @notice Get information about a specific request
    /// @param provider The address of the provider that handled the request
    /// @param sequenceNumber The unique identifier of the request
    /// @return req The request information including status, random number, and other metadata
    /// @dev This method allows querying the state of a previously made request. The returned Request struct
    /// contains information about whether the request was fulfilled, the generated random number (if available),
    /// and other metadata about the request.
    function getRequestV2(
        address provider,
        uint64 sequenceNumber
    ) external view returns (EntropyStructsV2.Request memory req);

    /// @notice Get the fee charged by the default provider for the default gas limit
    /// @return feeAmount The fee amount in wei
    /// @dev This method returns the base fee required to make a request using the default provider with
    /// the default gas limit. This fee should be passed as msg.value when calling requestV2().
    /// The fee can change over time, so this method should be called before each request.
    function getFeeV2() external view returns (uint128 feeAmount);

    /// @notice Get the fee charged by the default provider for a specific gas limit
    /// @param gasLimit The gas limit for the callback function
    /// @return feeAmount The fee amount in wei
    /// @dev This method returns the fee required to make a request using the default provider with
    /// the specified gas limit. This fee should be passed as msg.value when calling requestV2(gasLimit).
    /// The fee can change over time, so this method should be called before each request.
    function getFeeV2(
        uint32 gasLimit
    ) external view returns (uint128 feeAmount);

    /// @notice Get the fee charged by a specific provider for a request with a given gas limit
    /// @param provider The address of the provider to query
    /// @param gasLimit The gas limit for the callback function
    /// @return feeAmount The fee amount in wei
    /// @dev This method returns the fee required to make a request using the specified provider with
    /// the given gas limit. This fee should be passed as msg.value when calling requestV2(provider, gasLimit)
    /// or requestV2(provider, userRandomNumber, gasLimit). The fee can change over time, so this method
    /// should be called before each request.
    function getFeeV2(
        address provider,
        uint32 gasLimit
    ) external view returns (uint128 feeAmount);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.5.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_safeTransfer(token, to, value, true)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        if (!_safeTransferFrom(token, from, to, value, true)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _safeTransfer(token, to, value, false);
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _safeTransferFrom(token, from, to, value, false);
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_safeApprove(token, spender, value, false)) {
            if (!_safeApprove(token, spender, 0, true)) revert SafeERC20FailedOperation(address(token));
            if (!_safeApprove(token, spender, value, true)) revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that relies on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that relies on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Oppositely, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity `token.transfer(to, value)` call, relaxing the requirement on the return value: the
     * return value is optional (but if data is returned, it must not be false).
     *
     * @param token The token targeted by the call.
     * @param to The recipient of the tokens
     * @param value The amount of token to transfer
     * @param bubble Behavior switch if the transfer call reverts: bubble the revert reason or return a false boolean.
     */
    function _safeTransfer(IERC20 token, address to, uint256 value, bool bubble) private returns (bool success) {
        bytes4 selector = IERC20.transfer.selector;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(0x00, selector)
            mstore(0x04, and(to, shr(96, not(0))))
            mstore(0x24, value)
            success := call(gas(), token, 0, 0x00, 0x44, 0x00, 0x20)
            // if call success and return is true, all is good.
            // otherwise (not success or return is not true), we need to perform further checks
            if iszero(and(success, eq(mload(0x00), 1))) {
                // if the call was a failure and bubble is enabled, bubble the error
                if and(iszero(success), bubble) {
                    returndatacopy(fmp, 0x00, returndatasize())
                    revert(fmp, returndatasize())
                }
                // if the return value is not true, then the call is only successful if:
                // - the token address has code
                // - the returndata is empty
                success := and(success, and(iszero(returndatasize()), gt(extcodesize(token), 0)))
            }
            mstore(0x40, fmp)
        }
    }

    /**
     * @dev Imitates a Solidity `token.transferFrom(from, to, value)` call, relaxing the requirement on the return
     * value: the return value is optional (but if data is returned, it must not be false).
     *
     * @param token The token targeted by the call.
     * @param from The sender of the tokens
     * @param to The recipient of the tokens
     * @param value The amount of token to transfer
     * @param bubble Behavior switch if the transfer call reverts: bubble the revert reason or return a false boolean.
     */
    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value,
        bool bubble
    ) private returns (bool success) {
        bytes4 selector = IERC20.transferFrom.selector;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(0x00, selector)
            mstore(0x04, and(from, shr(96, not(0))))
            mstore(0x24, and(to, shr(96, not(0))))
            mstore(0x44, value)
            success := call(gas(), token, 0, 0x00, 0x64, 0x00, 0x20)
            // if call success and return is true, all is good.
            // otherwise (not success or return is not true), we need to perform further checks
            if iszero(and(success, eq(mload(0x00), 1))) {
                // if the call was a failure and bubble is enabled, bubble the error
                if and(iszero(success), bubble) {
                    returndatacopy(fmp, 0x00, returndatasize())
                    revert(fmp, returndatasize())
                }
                // if the return value is not true, then the call is only successful if:
                // - the token address has code
                // - the returndata is empty
                success := and(success, and(iszero(returndatasize()), gt(extcodesize(token), 0)))
            }
            mstore(0x40, fmp)
            mstore(0x60, 0)
        }
    }

    /**
     * @dev Imitates a Solidity `token.approve(spender, value)` call, relaxing the requirement on the return value:
     * the return value is optional (but if data is returned, it must not be false).
     *
     * @param token The token targeted by the call.
     * @param spender The spender of the tokens
     * @param value The amount of token to transfer
     * @param bubble Behavior switch if the transfer call reverts: bubble the revert reason or return a false boolean.
     */
    function _safeApprove(IERC20 token, address spender, uint256 value, bool bubble) private returns (bool success) {
        bytes4 selector = IERC20.approve.selector;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(0x00, selector)
            mstore(0x04, and(spender, shr(96, not(0))))
            mstore(0x24, value)
            success := call(gas(), token, 0, 0x00, 0x44, 0x00, 0x20)
            // if call success and return is true, all is good.
            // otherwise (not success or return is not true), we need to perform further checks
            if iszero(and(success, eq(mload(0x00), 1))) {
                // if the call was a failure and bubble is enabled, bubble the error
                if and(iszero(success), bubble) {
                    returndatacopy(fmp, 0x00, returndatasize())
                    revert(fmp, returndatasize())
                }
                // if the return value is not true, then the call is only successful if:
                // - the token address has code
                // - the returndata is empty
                success := and(success, and(iszero(returndatasize()), gt(extcodesize(token), 0)))
            }
            mstore(0x40, fmp)
        }
    }
}

// src/BullRaceBetting.sol

contract Moonad is ReentrancyGuard, Ownable, Pausable, IEntropyConsumer {
    using SafeERC20 for IERC20;

    // ======== CONSTANTS ========
    uint256 public constant HOUSE_RAKE_BPS = 1000; // 10% total rake
    uint256 public constant SWITCH_FEE_BPS = 500;  // 5%
    uint256 public constant SEEDER_RAKE_BPS = 200;  // 2% of pool goes to seeder (out of the 10%)
    uint256 private constant BPS_BASE = 10000;

    // Track multipliers: 10 track types × 6 stats (SPD, STA, ACC, STR, AGI, TMP)
    // Values match the frontend TRACK_MULTIPLIERS exactly.
    int8[6][10] private TRACK_MULTIPLIERS = [
        [int8(10),  1,  9,  1,  2,  4],   // Flat Sprint
        [int8( 5), 10,  0,  3,  1, -3],   // Endurance
        [int8(-4),  6, -2, 10,  3, -3],   // Mud Pit
        [int8(-2),  2,  3,  1, 10, -5],   // Rocky Canyon
        [int8(-2),  8,  2,  9,  1,  0],   // Steep Incline
        [int8( 8),  1,  1,  5,  5, -6],   // Downhill Rush
        [int8( 1),  2,  8, -3, 10,  3],   // Zigzag
        [int8( 1),  5,  1,  2,  6, -8],   // Thunderstorm
        [int8(-5),  7, -3,  9,  2, -2],   // Sand Dunes
        [int8( 3),  5,  2,  1,  6, -7]    // Night Trail
    ];

    // ======== ENUMS ========
    enum RacePhase { BETTING, SWITCHING, CLOSED, RESOLVED, CANCELLED }

    // ======== STRUCTS ========
    struct RaceConfig {
        address token;           // address(0) = native MON
        uint8   numBulls;
        uint8   trackType;
        bool    resolved;
        bool    cancelled;
        bool    seeded;
        uint8   payoutBullId;   // highest finisher with bets
        address seeder;          // who requested VRF seed — gets seeder reward
        uint256 totalPool;
        uint256 rakeAccumulated;
        bytes32 seed;           // Pyth Entropy randomness (stored for transparency)
        uint8[48] bullStats;    // 6 stats × 8 bulls, flattened
    }

    struct RaceResults {
        uint8[8]   finishOrder;  // bull IDs in finish order (index 0 = winner)
        uint256[8] finishTimes;  // milliseconds
        uint32     resolvedAt;   // timestamp
    }

    struct UserBet {
        uint8   bullId;
        bool    exists;
        bool    claimed;
        uint128 amount;
    }

    struct LeaderboardEntry {
        address player;
        uint256 winnings;
        uint256 wins;
    }

    // ======== STATE ========
    uint256 public epoch;              // UTC 00:00 of start day
    uint256 public cycleDuration = 900;      // 15 minutes
    uint256 public bettingDuration = 480;    // 0:00–8:00
    uint256 public switchingEnd = 660;       // switching ends at 11:00
    uint8   public defaultNumBulls = 8;
    address public defaultRaceToken;         // address(0) = native MON

    // Pyth Entropy
    IEntropyV2 public immutable entropy;

    // VRF request tracking: sequenceNumber → raceId
    mapping(uint64 => uint256) public vrfRequestToRace;

    // Token allowlist: token address => minBetAmount (0 means not accepted)
    mapping(address => uint256) public minBetAmount;
    mapping(address => bool) public acceptedTokens;
    address[] private _acceptedTokenList;

    // Per-token rake accumulation
    mapping(address => uint256) public rakeBalance;

    // Seeder reward balances: seeder address => token => claimable amount
    mapping(address => mapping(address => uint256)) public seederBalance;

    // Leaderboard: cumulative stats per address
    mapping(address => uint256) public totalWinnings;
    mapping(address => uint256) public racesWon;
    mapping(address => uint256) public totalBetsPlaced;

    // On-chain top-10 leaderboard
    LeaderboardEntry[10] public leaderboard;

    // Race data
    mapping(uint256 => RaceConfig) private _races;
    mapping(uint256 => RaceResults) private _results;
    mapping(uint256 => mapping(uint8 => uint256)) public bullPools;
    mapping(uint256 => mapping(address => UserBet)) private _userBets;

    // Track which races have been initialized (first bet or seed request)
    mapping(uint256 => bool) public raceInitialized;

    // ======== EVENTS ========
    event BetPlaced(uint256 indexed raceId, address indexed bettor, uint8 bullId, address token, uint256 amount);
    event BetSwitched(uint256 indexed raceId, address indexed bettor, uint8 oldBullId, uint8 newBullId, uint256 fee);
    event RaceSeedRequested(uint256 indexed raceId, uint64 sequenceNumber);
    event RaceSeeded(uint256 indexed raceId, uint8 trackType, bytes32 seed);
    event RaceResolved(uint256 indexed raceId, uint8[8] finishOrder, uint256[8] finishTimes, uint256 totalPool);
    event WinningsClaimed(uint256 indexed raceId, address indexed bettor, uint256 payout);
    event RefundClaimed(uint256 indexed raceId, address indexed bettor, uint256 amount);
    event RaceCancelled(uint256 indexed raceId);
    event RakeWithdrawn(address indexed token, address indexed to, uint256 amount);
    event SeederRewardCredited(uint256 indexed raceId, address indexed seeder, uint256 amount);
    event SeederRewardClaimed(address indexed seeder, address indexed token, uint256 amount);
    event TokenAdded(address indexed token, uint256 minBet);
    event TokenRemoved(address indexed token);
    event TimingConfigUpdated(uint256 cycle, uint256 betting, uint256 switchingEnd);

    // ======== CONSTRUCTOR ========
    constructor(uint256 _epoch, address _entropy) Ownable(msg.sender) {
        require(_epoch <= block.timestamp, "Epoch must be in the past");
        require(_entropy != address(0), "Zero entropy address");
        epoch = _epoch;
        entropy = IEntropyV2(_entropy);
    }

    // ======== PYTH ENTROPY VRF ========

    /// @notice Returns the Pyth Entropy contract address (required by IEntropyConsumer)
    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    /// @notice Request VRF randomness for a race. Anyone can call. Caller pays Entropy fee.
    /// @param raceId The race to seed
    function requestRaceSeed(uint256 raceId) external payable whenNotPaused {
        require(raceId == getCurrentRaceId(), "Can only seed current race");
        RaceConfig storage race = _races[raceId];

        RacePhase phase = getRacePhase(raceId);
        require(
            phase == RacePhase.BETTING || phase == RacePhase.SWITCHING,
            "Too late to seed"
        );
        require(!race.seeded, "Already seeded");

        // Initialize if not yet
        if (!raceInitialized[raceId]) {
            _initRace(raceId, defaultRaceToken);
        }

        // Record seeder (first caller gets credit)
        if (race.seeder == address(0)) {
            race.seeder = msg.sender;
        }

        // Get Entropy fee and request randomness
        uint128 fee = entropy.getFeeV2();
        require(msg.value >= fee, "Insufficient Entropy fee");

        uint64 sequenceNumber = entropy.requestV2{value: fee}();
        vrfRequestToRace[sequenceNumber] = raceId;

        // Refund excess
        if (msg.value > fee) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - fee}("");
            require(ok, "Refund failed");
        }

        emit RaceSeedRequested(raceId, sequenceNumber);
    }

    /// @notice Pyth Entropy callback — derives stats + trackType on-chain from randomness.
    ///         Called automatically by Pyth keeper network.
    function entropyCallback(
        uint64 sequenceNumber,
        address /* provider */,
        bytes32 randomNumber
    ) internal override {
        uint256 raceId = vrfRequestToRace[sequenceNumber];
        RaceConfig storage race = _races[raceId];

        // Guard: don't overwrite if already seeded
        if (race.seeded) return;

        // Initialize if not yet (edge case: seed requested before any bet)
        if (!raceInitialized[raceId]) {
            _initRace(raceId, defaultRaceToken);
        }

        uint256 randomness = uint256(randomNumber);

        // Store raw randomness for transparency
        race.seed = randomNumber;

        // Derive trackType
        race.trackType = uint8(randomness % 10);

        // Derive 48 bull stats (8 bulls × 6 stats each), values 1-10
        for (uint256 i = 0; i < 48; i++) {
            race.bullStats[i] = uint8(
                (uint256(keccak256(abi.encode(randomness, i))) % 10) + 1
            );
        }

        race.seeded = true;

        emit RaceSeeded(raceId, race.trackType, race.seed);
    }

    /// @notice View: get the current Pyth Entropy fee for seeding a race
    function getEntropyFee() external view returns (uint128) {
        return entropy.getFeeV2();
    }

    // ====================================================================
    //                       TIME / PHASE HELPERS
    // ====================================================================

    function getCurrentRaceId() public view returns (uint256) {
        require(block.timestamp >= epoch, "Before epoch");
        return (block.timestamp - epoch) / cycleDuration;
    }

    function getRaceStartTime(uint256 raceId) public view returns (uint256) {
        return epoch + raceId * cycleDuration;
    }

    function getRacePhase(uint256 raceId) public view returns (RacePhase) {
        RaceConfig storage race = _races[raceId];
        if (race.cancelled) return RacePhase.CANCELLED;
        if (race.resolved) return RacePhase.RESOLVED;

        uint256 raceStart = getRaceStartTime(raceId);
        if (block.timestamp < raceStart) return RacePhase.BETTING; // future race

        uint256 elapsed = block.timestamp - raceStart;

        if (elapsed < bettingDuration) return RacePhase.BETTING;
        if (elapsed < switchingEnd) return RacePhase.SWITCHING;
        return RacePhase.CLOSED;
    }

    function isBettingOpen(uint256 raceId) public view returns (bool) {
        return getRacePhase(raceId) == RacePhase.BETTING;
    }

    function isSwitchingOpen(uint256 raceId) public view returns (bool) {
        RacePhase phase = getRacePhase(raceId);
        return phase == RacePhase.BETTING || phase == RacePhase.SWITCHING;
    }

    function getPhaseTimeRemaining(uint256 raceId) public view returns (uint256) {
        RaceConfig storage race = _races[raceId];
        if (race.cancelled || race.resolved) return 0;

        uint256 raceStart = getRaceStartTime(raceId);
        if (block.timestamp < raceStart) return raceStart - block.timestamp + bettingDuration;

        uint256 elapsed = block.timestamp - raceStart;

        if (elapsed < bettingDuration) {
            return bettingDuration - elapsed;
        } else if (elapsed < switchingEnd) {
            return switchingEnd - elapsed;
        } else if (elapsed < cycleDuration) {
            return cycleDuration - elapsed;
        }
        return 0;
    }

    // ====================================================================
    //                            BETTING
    // ====================================================================

    function placeBet(
        uint256 raceId,
        uint8 bullId,
        address token,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        require(raceId == getCurrentRaceId(), "Can only bet current race");
        require(isBettingOpen(raceId), "Betting not open");

        RaceConfig storage race = _races[raceId];

        // Initialize race on first interaction
        if (!raceInitialized[raceId]) {
            _initRace(raceId, token);
        }

        require(token == race.token, "Wrong token for this race");
        require(acceptedTokens[token], "Token not accepted");
        require(bullId < race.numBulls, "Invalid bull ID");

        UserBet storage bet = _userBets[raceId][msg.sender];
        require(!bet.exists, "Already bet");

        // Handle payment
        uint256 betAmount = _collectPayment(token, amount);
        require(betAmount >= minBetAmount[token], "Below minimum bet");

        // Store bet
        bet.bullId = bullId;
        bet.exists = true;
        bet.amount = uint128(betAmount);

        bullPools[raceId][bullId] += betAmount;
        race.totalPool += betAmount;
        totalBetsPlaced[msg.sender] += 1;

        emit BetPlaced(raceId, msg.sender, bullId, token, betAmount);
    }

    function switchBet(uint256 raceId, uint8 newBullId) external nonReentrant whenNotPaused {
        require(isSwitchingOpen(raceId), "Switching not open");

        RaceConfig storage race = _races[raceId];
        UserBet storage bet = _userBets[raceId][msg.sender];

        require(bet.exists, "No existing bet");
        require(newBullId < race.numBulls, "Invalid bull ID");
        require(newBullId != bet.bullId, "Same bull");

        uint8 oldBullId = bet.bullId;
        uint256 oldAmount = uint256(bet.amount);
        uint256 fee = (oldAmount * SWITCH_FEE_BPS) / BPS_BASE;
        uint256 newAmount = oldAmount - fee;

        // Update pools
        bullPools[raceId][oldBullId] -= oldAmount;
        bullPools[raceId][newBullId] += newAmount;
        race.totalPool -= fee;

        // Fee goes to house rake
        rakeBalance[race.token] += fee;
        race.rakeAccumulated += fee;

        // Update user bet
        bet.bullId = newBullId;
        bet.amount = uint128(newAmount);

        emit BetSwitched(raceId, msg.sender, oldBullId, newBullId, fee);
    }

    // ====================================================================
    //                            CLAIMS
    // ====================================================================

    function claimWinnings(uint256 raceId) external nonReentrant {
        RaceConfig storage race = _races[raceId];

        // Lazy resolution: auto-resolve if seeded + CLOSED but not yet resolved
        if (!race.resolved && race.seeded && !race.cancelled && getRacePhase(raceId) == RacePhase.CLOSED) {
            _resolveRace(raceId);
        }
        require(race.resolved, "Not resolved");

        UserBet storage bet = _userBets[raceId][msg.sender];
        require(bet.exists, "No bet placed");
        require(!bet.claimed, "Already claimed");
        require(bet.bullId == race.payoutBullId, "Not a winner");

        bet.claimed = true;

        uint256 netPool = race.totalPool - race.rakeAccumulated;
        uint256 userBet = uint256(bet.amount);
        uint256 winningPool = bullPools[raceId][race.payoutBullId];
        uint256 payout = (netPool * userBet) / winningPool;

        // Update leaderboard stats
        totalWinnings[msg.sender] += payout;
        racesWon[msg.sender] += 1;
        _updateLeaderboard(msg.sender);

        _sendPayment(race.token, msg.sender, payout);

        emit WinningsClaimed(raceId, msg.sender, payout);
    }

    function claimRefund(uint256 raceId) external nonReentrant {
        RaceConfig storage race = _races[raceId];
        // Allow refund if cancelled OR if race ended without a seed (bettors shouldn't lose funds)
        require(
            race.cancelled ||
            (getRacePhase(raceId) == RacePhase.CLOSED && !race.seeded && !race.resolved),
            "Race not refundable"
        );

        UserBet storage bet = _userBets[raceId][msg.sender];
        require(bet.exists, "No bet placed");
        require(!bet.claimed, "Already claimed");

        bet.claimed = true;

        uint256 refundAmount = uint256(bet.amount);
        _sendPayment(race.token, msg.sender, refundAmount);

        emit RefundClaimed(raceId, msg.sender, refundAmount);
    }

    /// @notice Seeders claim accumulated rewards across all races they seeded
    function claimSeederReward(address token) external nonReentrant {
        uint256 amount = seederBalance[msg.sender][token];
        require(amount > 0, "No seeder reward");
        seederBalance[msg.sender][token] = 0;
        _sendPayment(token, msg.sender, amount);
        emit SeederRewardClaimed(msg.sender, token, amount);
    }

    // ====================================================================
    //                    PERMISSIONLESS RACE RESOLUTION
    // ====================================================================

    /// @notice Resolve a race on-chain. Anyone can call — results are deterministic from VRF seed.
    /// @param raceId The race to resolve
    function resolveRace(uint256 raceId) external nonReentrant {
        _resolveRace(raceId);
    }

    /// @notice Internal resolution logic. Called by resolveRace() or lazily by claimWinnings().
    function _resolveRace(uint256 raceId) internal {
        RaceConfig storage race = _races[raceId];

        require(getRacePhase(raceId) == RacePhase.CLOSED, "Race not in closed phase");
        require(!race.resolved, "Already resolved");
        require(!race.cancelled, "Race cancelled");
        require(race.seeded, "Race not seeded");

        // Compute scores and sorted finish order
        (uint8[8] memory finishOrder, uint256[8] memory finishTimes) = _computeResults(
            race.numBulls, race.seed, race.trackType, race.bullStats
        );

        // Distribute rake
        _distributeRake(raceId, race);

        // Find payout bull: first finisher with bets
        for (uint8 i = 0; i < race.numBulls; i++) {
            if (bullPools[raceId][finishOrder[i]] > 0) {
                race.payoutBullId = finishOrder[i];
                break;
            }
        }

        race.resolved = true;

        // Store results
        RaceResults storage results = _results[raceId];
        results.finishOrder = finishOrder;
        results.finishTimes = finishTimes;
        results.resolvedAt = uint32(block.timestamp);

        emit RaceResolved(raceId, finishOrder, finishTimes, race.totalPool);
    }

    /// @notice Compute scores, sort, and derive finish times — pure computation, no state writes.
    function _computeResults(
        uint8 numBulls,
        bytes32 seed,
        uint8 trackType,
        uint8[48] storage bullStats
    ) internal view returns (uint8[8] memory finishOrder, uint256[8] memory finishTimes) {
        int256[8] memory scores;
        int8[6] memory mults = TRACK_MULTIPLIERS[trackType];

        for (uint8 i = 0; i < numBulls; i++) {
            int256 score = 0;
            for (uint8 j = 0; j < 6; j++) {
                int256 stat = int256(uint256(bullStats[i * 6 + j]));
                score += j == 5 ? (stat - 5) * int256(mults[j]) : stat * int256(mults[j]);
            }
            score += int256(uint256(keccak256(abi.encode(seed, i))) % 20);
            scores[i] = score;
        }

        // Sort by score descending (insertion sort, max 8 elements)
        for (uint8 i = 0; i < numBulls; i++) finishOrder[i] = i;
        for (uint8 i = 1; i < numBulls; i++) {
            uint8 key = finishOrder[i];
            int256 keyScore = scores[key];
            uint8 j = i;
            while (j > 0 && scores[finishOrder[j - 1]] < keyScore) {
                finishOrder[j] = finishOrder[j - 1];
                j--;
            }
            finishOrder[j] = key;
        }

        // Derive cosmetic finish times
        int256 topScore = scores[finishOrder[0]];
        for (uint8 i = 0; i < numBulls; i++) {
            finishTimes[i] = 25000 + uint256(topScore - scores[finishOrder[i]]) * 200;
        }
    }

    /// @notice Distribute rake between house and seeder.
    function _distributeRake(uint256 raceId, RaceConfig storage race) internal {
        uint256 totalRake = (race.totalPool * HOUSE_RAKE_BPS) / BPS_BASE;
        uint256 additionalRake = 0;
        if (totalRake > race.rakeAccumulated) {
            additionalRake = totalRake - race.rakeAccumulated;
        }
        race.rakeAccumulated = totalRake;

        uint256 seederCut = 0;
        if (race.seeder != address(0) && race.totalPool > 0) {
            seederCut = (race.totalPool * SEEDER_RAKE_BPS) / BPS_BASE;
            if (seederCut > additionalRake) seederCut = additionalRake;
            seederBalance[race.seeder][race.token] += seederCut;
            emit SeederRewardCredited(raceId, race.seeder, seederCut);
        }
        rakeBalance[race.token] += (additionalRake - seederCut);
    }

    // ====================================================================
    //                        OWNER ADMIN FUNCTIONS
    // ====================================================================

    function cancelRace(uint256 raceId) external onlyOwner {
        RaceConfig storage race = _races[raceId];
        require(!race.resolved, "Already resolved");
        require(!race.cancelled, "Already cancelled");

        race.cancelled = true;

        // Refund any switch-fee rake accumulated for this race
        if (race.rakeAccumulated > 0 && rakeBalance[race.token] >= race.rakeAccumulated) {
            rakeBalance[race.token] -= race.rakeAccumulated;
            race.totalPool += race.rakeAccumulated;
            race.rakeAccumulated = 0;
        }

        emit RaceCancelled(raceId);
    }

    function setEpoch(uint256 _epoch) external onlyOwner {
        require(_epoch <= block.timestamp, "Epoch must be in the past");
        epoch = _epoch;
    }

    function setTimingConfig(
        uint256 _cycleDuration,
        uint256 _bettingDuration,
        uint256 _switchingEnd
    ) external onlyOwner {
        require(_bettingDuration < _switchingEnd, "Betting must end before switching");
        require(_switchingEnd < _cycleDuration, "Switching must end before cycle");
        require(_cycleDuration > 0, "Cycle must be > 0");

        cycleDuration = _cycleDuration;
        bettingDuration = _bettingDuration;
        switchingEnd = _switchingEnd;

        emit TimingConfigUpdated(_cycleDuration, _bettingDuration, _switchingEnd);
    }

    function setNumBulls(uint8 n) external onlyOwner {
        require(n >= 2 && n <= 16, "Invalid bull count");
        defaultNumBulls = n;
    }

    function addAcceptedToken(address token, uint256 _minBet) external onlyOwner {
        if (!acceptedTokens[token]) {
            acceptedTokens[token] = true;
            _acceptedTokenList.push(token);
        }
        minBetAmount[token] = _minBet;
        emit TokenAdded(token, _minBet);
    }

    function removeAcceptedToken(address token) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        acceptedTokens[token] = false;
        for (uint256 i = 0; i < _acceptedTokenList.length; i++) {
            if (_acceptedTokenList[i] == token) {
                _acceptedTokenList[i] = _acceptedTokenList[_acceptedTokenList.length - 1];
                _acceptedTokenList.pop();
                break;
            }
        }
        emit TokenRemoved(token);
    }

    function setMinBetAmount(address token, uint256 _minBet) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        minBetAmount[token] = _minBet;
    }

    function setDefaultRaceToken(address token) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        defaultRaceToken = token;
    }

    function withdrawRake(address token, address to) external onlyOwner {
        require(to != address(0), "Zero address");
        uint256 amount = rakeBalance[token];
        require(amount > 0, "No rake to withdraw");
        rakeBalance[token] = 0;

        _sendPayment(token, to, amount);

        emit RakeWithdrawn(token, to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ====================================================================
    //                         VIEW FUNCTIONS
    // ====================================================================

    function getRaceInfo(uint256 raceId) external view returns (
        RacePhase phase,
        address token,
        uint256 totalPool,
        uint8 numBulls,
        bool resolved,
        bool cancelled
    ) {
        RaceConfig storage race = _races[raceId];
        return (
            getRacePhase(raceId),
            race.token,
            race.totalPool,
            race.numBulls,
            race.resolved,
            race.cancelled
        );
    }

    function getRaceResults(uint256 raceId) external view returns (
        uint8[8] memory finishOrder,
        uint256[8] memory finishTimes,
        uint32 resolvedAt
    ) {
        RaceResults storage results = _results[raceId];
        return (results.finishOrder, results.finishTimes, results.resolvedAt);
    }

    function getRaceSeedData(uint256 raceId) external view returns (
        uint8[48] memory stats,
        uint8 trackType,
        bytes32 seed,
        bool seeded
    ) {
        RaceConfig storage race = _races[raceId];
        return (race.bullStats, race.trackType, race.seed, race.seeded);
    }

    function getBullPool(uint256 raceId, uint8 bullId) external view returns (uint256) {
        return bullPools[raceId][bullId];
    }

    function getAllBullPools(uint256 raceId) external view returns (uint256[8] memory pools) {
        for (uint8 i = 0; i < 8; i++) {
            pools[i] = bullPools[raceId][i];
        }
    }

    function getUserBet(uint256 raceId, address user) external view returns (
        bool exists,
        uint8 bullId,
        uint256 amount,
        bool claimed
    ) {
        UserBet storage bet = _userBets[raceId][user];
        return (bet.exists, bet.bullId, uint256(bet.amount), bet.claimed);
    }

    function getPotentialPayout(
        uint256 raceId,
        uint8 bullId,
        uint256 amount
    ) external view returns (uint256) {
        RaceConfig storage race = _races[raceId];
        uint256 newTotal = race.totalPool + amount;
        uint256 newBullPool = bullPools[raceId][bullId] + amount;
        uint256 netPool = (newTotal * (BPS_BASE - HOUSE_RAKE_BPS)) / BPS_BASE;
        if (newBullPool == 0) return 0;
        return (netPool * amount) / newBullPool;
    }

    function getAcceptedTokens() external view returns (address[] memory) {
        return _acceptedTokenList;
    }

    /// @notice Get the track multipliers for a given track type
    function getTrackMultipliers(uint8 trackType) external view returns (int8[6] memory) {
        require(trackType < 10, "Invalid track type");
        return TRACK_MULTIPLIERS[trackType];
    }

    /// @notice Get the seeder address for a race
    function getRaceSeeder(uint256 raceId) external view returns (address) {
        return _races[raceId].seeder;
    }

    /// @notice Get a seeder's claimable reward balance for a token
    function getSeederBalance(address seeder, address token) external view returns (uint256) {
        return seederBalance[seeder][token];
    }

    // ====================================================================
    //                         LEADERBOARD
    // ====================================================================

    /// @notice Update the top-10 leaderboard after a claim. O(10) worst case.
    function _updateLeaderboard(address player) internal {
        uint256 w = totalWinnings[player];
        uint256 wins = racesWon[player];

        // Check if player is already on the board
        int256 existIdx = -1;
        for (uint256 i = 0; i < 10; i++) {
            if (leaderboard[i].player == player) {
                existIdx = int256(i);
                break;
            }
        }

        if (existIdx >= 0) {
            // Update stats in place
            uint256 idx = uint256(existIdx);
            leaderboard[idx].winnings = w;
            leaderboard[idx].wins = wins;
            // Bubble up if needed
            while (idx > 0 && leaderboard[idx].winnings > leaderboard[idx - 1].winnings) {
                LeaderboardEntry memory tmp = leaderboard[idx - 1];
                leaderboard[idx - 1] = leaderboard[idx];
                leaderboard[idx] = tmp;
                idx--;
            }
        } else {
            // Not on board — check if qualifies (better than last entry)
            if (w > leaderboard[9].winnings) {
                leaderboard[9] = LeaderboardEntry(player, w, wins);
                // Bubble up
                uint256 idx = 9;
                while (idx > 0 && leaderboard[idx].winnings > leaderboard[idx - 1].winnings) {
                    LeaderboardEntry memory tmp = leaderboard[idx - 1];
                    leaderboard[idx - 1] = leaderboard[idx];
                    leaderboard[idx] = tmp;
                    idx--;
                }
            }
        }
    }

    /// @notice Get the full top-10 leaderboard
    function getLeaderboard() external view returns (LeaderboardEntry[10] memory) {
        return leaderboard;
    }

    /// @notice Owner-only: seed leaderboard from old contract data (migration helper)
    function seedLeaderboard(
        address[] calldata players,
        uint256[] calldata winnings,
        uint256[] calldata wins
    ) external onlyOwner {
        require(players.length == winnings.length && players.length == wins.length, "Length mismatch");
        require(players.length <= 10, "Max 10 entries");
        for (uint256 i = 0; i < players.length; i++) {
            leaderboard[i] = LeaderboardEntry(players[i], winnings[i], wins[i]);
            totalWinnings[players[i]] = winnings[i];
            racesWon[players[i]] = wins[i];
        }
    }

    // ====================================================================
    //                         INTERNAL HELPERS
    // ====================================================================

    function _initRace(uint256 raceId, address token) internal {
        RaceConfig storage race = _races[raceId];
        race.token = token;
        race.numBulls = defaultNumBulls;
        raceInitialized[raceId] = true;
    }

    function _collectPayment(address token, uint256 amount) internal returns (uint256) {
        if (token == address(0)) {
            // Native MON
            require(msg.value > 0, "No value sent");
            return msg.value;
        } else {
            // ERC20
            require(msg.value == 0, "Do not send MON with ERC20 bet");
            require(amount > 0, "Amount must be > 0");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            return amount;
        }
    }

    function _sendPayment(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            (bool ok, ) = payable(to).call{value: amount}("");
            require(ok, "Native transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Accept native MON for Entropy fees
    receive() external payable {}
}

