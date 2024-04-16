// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {State, WeightKind, CompoundKeyKind} from "./IState.sol";

enum OpKind {
    EdgeSet,
    EdgeRemove,
    AnnotationSet,
    DataSet
}

struct Op {
    OpKind kind;
    bytes4 relID;
    uint8 relKey;
    bytes24 srcNodeID;
    bytes24 dstNodeID;
    uint160 weight;
    string annName;
    string annData;
    bytes32 nodeData;
}

/* StateOpsRecorder is a contract that wraps a State implementation and logs all operations
 * performed on it. It is expected that this contract will be called using ETH_CALL so
 * as not to keep the collected Ops on chain.
 */

contract StateOpsRecorder is State {
    State state;

    Op[] ops;

    modifier ownerOnly() {
        require(msg.sender == state.getOwner(), "BaseState: Sender is not the owner");
        _;
    }

    modifier allowListOnly() {
        require(state.isAllowed(msg.sender), "BaseState: Sender is not on the allowlist");
        _;
    }

    constructor(State _state) {
        state = _state;
    }

    function getOwner() external view returns (address) {
        return state.getOwner();
    }

    function isAllowed(address addr) external view returns (bool) {
        return state.isAllowed(addr);
    }

    function set(bytes4 relID, uint8 relKey, bytes24 srcNodeID, bytes24 dstNodeID, uint64 weight)
        external
        allowListOnly
    {
        state.set(relID, relKey, srcNodeID, dstNodeID, weight);

        Op storage op = ops.push();
        op.kind = OpKind.EdgeSet;
        op.relID = relID;
        op.relKey = relKey;
        op.srcNodeID = srcNodeID;
        op.dstNodeID = dstNodeID;
        op.weight = weight;
    }

    function remove(bytes4 relID, uint8 relKey, bytes24 srcNodeID) external allowListOnly {
        state.remove(relID, relKey, srcNodeID);

        Op storage op = ops.push();
        op.kind = OpKind.EdgeRemove;
        op.relID = relID;
        op.relKey = relKey;
        op.srcNodeID = srcNodeID;
    }

    function get(bytes4 relID, uint8 relKey, bytes24 srcNodeID)
        external
        view
        returns (bytes24 dstNodeId, uint64 weight)
    {
        return state.get(relID, relKey, srcNodeID);
    }

    function registerNodeType(bytes4, /*kindID*/ string memory, /*kindName*/ CompoundKeyKind /*keyKind*/ )
        external
        view
        ownerOnly
    {
        revert("StateOpsRecorder: registerNodeType not supported for StateOpsRecorder");
    }

    function registerEdgeType(bytes4, /*relID*/ string memory, /*relName*/ WeightKind /*weightKind*/ )
        external
        view
        ownerOnly
    {
        revert("StateOpsRecorder: registerEdgeType not supported for StateOpsRecorder");
    }

    function authorizeContract(address /*addr*/ ) external view ownerOnly {
        revert("StateOpsRecorder: authorizeContract not supported for StateOpsRecorder");
    }

    function annotate(bytes24 nodeID, string memory label, string memory annotationData) external allowListOnly {
        state.annotate(nodeID, label, annotationData);

        Op storage op = ops.push();
        op.kind = OpKind.AnnotationSet;
        op.srcNodeID = nodeID;
        op.annName = label;
        op.annData = annotationData;
    }

    function setData(bytes24 nodeID, string memory label, bytes32 data) external allowListOnly {
        state.setData(nodeID, label, data);

        Op storage op = ops.push();
        op.kind = OpKind.DataSet;
        op.srcNodeID = nodeID;
        op.annName = label;
        op.nodeData = data;
    }

    function getData(bytes24 nodeID, string memory annotationLabel) external view returns (bytes32) {
        return state.getData(nodeID, annotationLabel);
    }

    // Op related functions

    function getHead() public view returns (uint256) {
        return ops.length;
    }

    function getOps(uint256 from, uint256 to) public view returns (Op[] memory res) {
        if (from == to) {
            res = new Op[](0);
            return res;
        }
        require(to > from, "TO must be after FROM");
        res = new Op[](to - from);
        for (uint256 i = 0; i < res.length; i++) {
            res[i] = ops[from + i];
        }
        return res;
    }
}
