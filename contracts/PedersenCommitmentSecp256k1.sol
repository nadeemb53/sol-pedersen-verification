// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EllipticCurve.sol";
import "./Secp256k1.sol";

contract PedersenCommitmentSecp256k1 is Secp256k1 {
    using SafeMath for uint256;

    uint256 public H;

    modifier isHSet() {
        require(H == 0);
        _;
    }

    function setH() external isHSet {
        uint256 TH = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        uint256 _p = pp;
        assembly {
            TH := mod(TH, _p)
        }
        H = TH;
    }

    function addmodP(
        uint256 _v1,
        uint256 _v2
    ) internal view returns (uint256 _v3) {
        uint256 _p = nn;
        assembly {
            _v3 := addmod(_v1, _v2, _p)
        }
    }

    function submodP(
        uint256 _v1,
        uint256 _v2
    ) internal view returns (uint256 _v3) {
        uint256 _p = nn;
        assembly {
            if lt(_v1, _v2) {
                _v3 := sub(_p, sub(_v2, _v1))
            }
            if gt(_v1, _v2) {
                _v3 := mod(sub(_v1, _v2), _p)
            }
        }
    }

    function commit(
        uint256 _r,
        uint256 _v
    ) public view returns (uint256 _x3, uint256 _y3) {
        (uint256 _lx, uint256 _ly) = eMul(H, gx, gy);
        (uint256 _x1, uint256 _y1) = eMul(_r, gx, gy);
        (uint256 _x2, uint256 _y2) = eMul(_v, _lx, _ly);
        (_x3, _y3) = eAdd(_x1, _y1, _x2, _y2);
    }

    function commitWithH(
        uint256 _r,
        uint256 _v,
        uint256 _hx,
        uint256 _hy
    ) public view returns (uint256 _x3, uint256 _y3) {
        (uint256 _x1, uint256 _y1) = eMul(_r, gx, gy);
        (uint256 _x2, uint256 _y2) = eMul(_v, _hx, _hy);
        (_x3, _y3) = eAdd(_x1, _y1, _x2, _y2);
    }

    function verify(
        uint256 _r,
        uint256 _v,
        uint256 _x1,
        uint256 _y1
    ) public view returns (bool result) {
        (uint256 _x2, uint256 _y2) = commit(_r, _v);
        if ((_x1 == _x2) && (_y1 == _y2)) {
            result = true;
        }
    }

    // This function verifies a Pedersen commitment by explicitly providing the generator point H. It takes six input parameters:
    // _r: The value of the randomness used in the commitment.
    // _v: The value being committed to.
    // _x1: The x-coordinate of the computed commitment point.
    // _y1: The y-coordinate of the computed commitment point.
    // _hx: The x-coordinate of the generator point H.
    // _hy: The y-coordinate of the generator point H.

    function verifyWithH(
        uint256 _r,
        uint256 _v,
        uint256 _x1,
        uint256 _y1,
        uint256 _hx,
        uint256 _hy
    ) public view returns (bool result) {
        (uint256 _x2, uint256 _y2) = commitWithH(_r, _v, _hx, _hy);
        if ((_x1 == _x2) && (_y1 == _y2)) {
            result = true;
        }
    }

    function addCommitment(
        uint256 _r1,
        uint256 _x1,
        uint256 _y1,
        uint256 _r2,
        uint256 _x2,
        uint256 _y2
    ) public view returns (uint256 _r3, uint256 _x3, uint256 _y3) {
        _r3 = addmodP(_r1, _r2);
        (_x3, _y3) = eAdd(_x1, _y1, _x2, _y2);
    }

    function subCommitment(
        uint256 _r1,
        uint256 _x1,
        uint256 _y1,
        uint256 _r2,
        uint256 _x2,
        uint256 _y2
    ) public view returns (uint256 _r3, uint256 _x3, uint256 _y3) {
        _r3 = submodP(_r1, _r2);
        (_x3, _y3) = eSub(_x1, _y1, _x2, _y2);
    }
}
