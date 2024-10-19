// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDetectionBot, IForta} from "./Interfaces.sol";

contract DetectionBot is IDetectionBot {
    IForta forta;
    constructor(IForta _forta) {
        forta = _forta;
    }
    function handleTransaction(
        address user,
        bytes calldata /* msgData */
    ) external {
        forta.raiseAlert(user);
    }
}
