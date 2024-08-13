// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20TokenLocker is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct LockInfo {
        address owner;
        uint256 amount;
        uint256 unlockTime;
        bool isLPToken;
        string title;
    }

    struct VestingInfo {
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 tgePercentage;
        uint256 cycleTime;
        uint256 cycleReleasePercent;
        uint256 releasedAmount;
        bool isLPToken;
        string title;
    }

    mapping(address => LockInfo[]) public locks;
    mapping(address => VestingInfo[]) public vestings;

    event TokensLocked(
        address indexed owner,
        address indexed token,
        uint256 amount,
        uint256 unlockTime,
        string title
    );
    event TokensVested(
        address indexed owner,
        address indexed token,
        uint256 amount,
        uint256 startTime,
        uint256 tgePercentage,
        uint256 cycleTime,
        uint256 cycleReleasePercent,
        string title
    );
    event TokensUnlocked(address indexed owner, address indexed token, uint256 amount);
    event TokensReleased(address indexed owner, address indexed token, uint256 amount);

    // Lock tokens without vesting
    function lock(
        address token,
        bool isLPToken,
        uint256 amount,
        uint256 unlockTime,
        string memory title
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        locks[token].push(LockInfo({
            owner: msg.sender,
            amount: amount,
            unlockTime: unlockTime,
            isLPToken: isLPToken,
            title: title
        }));

        emit TokensLocked(msg.sender, token, amount, unlockTime, title);
    }

    // Lock tokens with vesting
    function vestingLock(
        address token,
        bool isLPToken,
        uint256 amount,
        uint256 startTime,
        uint256 tgePercentage,
        uint256 cycleTime,
        uint256 cycleReleasePercent,
        string memory title
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(startTime > block.timestamp, "Start time must be in the future");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        vestings[token].push(VestingInfo({
            owner: msg.sender,
            amount: amount,
            startTime: startTime,
            tgePercentage: tgePercentage,
            cycleTime: cycleTime,
            cycleReleasePercent: cycleReleasePercent,
            releasedAmount: 0,
            isLPToken: isLPToken,
            title: title
        }));

        emit TokensVested(msg.sender, token, amount, startTime, tgePercentage, cycleTime, cycleReleasePercent, title);
    }

    // Unlock tokens after the lock period
    function unlock(address token, uint256 index) external nonReentrant {
        LockInfo storage lockInfo = locks[token][index];
        require(msg.sender == lockInfo.owner, "Only the owner can unlock");
        require(block.timestamp >= lockInfo.unlockTime, "Tokens are still locked");

        uint256 amount = lockInfo.amount;
        delete locks[token][index];

        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokensUnlocked(msg.sender, token, amount);
    }

    // Release tokens according to the vesting schedule
    function releaseVestedTokens(address token, uint256 index) external nonReentrant {
        VestingInfo storage vestingInfo = vestings[token][index];
        require(msg.sender == vestingInfo.owner, "Only the owner can release tokens");

        uint256 totalReleasable = calculateReleasableAmount(vestingInfo);
        require(totalReleasable > 0, "No tokens available for release");

        vestingInfo.releasedAmount += totalReleasable;

        IERC20(token).safeTransfer(msg.sender, totalReleasable);

        emit TokensReleased(msg.sender, token, totalReleasable);
    }

    // Calculate the releasable amount for vesting
    function calculateReleasableAmount(VestingInfo storage vestingInfo) internal view returns (uint256) {
        uint256 tgeAmount = (vestingInfo.amount * vestingInfo.tgePercentage) / 10000;
        uint256 releasableAmount = tgeAmount;

        if (block.timestamp > vestingInfo.startTime) {
            uint256 elapsedCycles = (block.timestamp - vestingInfo.startTime) / vestingInfo.cycleTime;
            uint256 cycleReleaseAmount = (vestingInfo.amount * vestingInfo.cycleReleasePercent) / 10000;
            releasableAmount += elapsedCycles * cycleReleaseAmount;
        }

        return releasableAmount - vestingInfo.releasedAmount;
    }
}
