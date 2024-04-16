// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {State, WeightKind, CompoundKeyKind, AnnotationKind} from "./IState.sol";
import {StateOpsRecorder} from "./StateOpsRecorder.sol";

error StateUnauthorizedSender();

contract BaseState is State {
    struct EdgeData {
        bytes24 dstNodeID;
        uint64 weight;
    }

    address owner;

    mapping(bytes24 => mapping(bytes4 => mapping(uint8 => EdgeData))) edges;
    mapping(bytes24 => mapping(bytes32 => bytes32)) annotations;
    mapping(bytes24 => mapping(bytes32 => bytes32)) nodeData;
    mapping(address => bool) allowlist;

    StateOpsRecorder stateOpsRecorder;

    modifier ownerOnly() {
        require(msg.sender == owner, "BaseState: Sender is not the owner");
        _;
    }

    modifier allowListOnly() {
        require(allowlist[msg.sender], "BaseState: Sender is not on the allowlist");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        allowlist[_owner] = true;
        // register the zero value under the kind name NULL
        _registerNodeType(0, "NULL", CompoundKeyKind.NONE);

        // Preferably we'd instantiate the shim outside of the contract however for convience
        // due to access control, we'll do it here.
        stateOpsRecorder = new StateOpsRecorder(this);
        allowlist[address(stateOpsRecorder)] = true;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function isAllowed(address addr) external view returns (bool) {
        return allowlist[addr];
    }

    function set(bytes4 relID, uint8 relKey, bytes24 srcNodeID, bytes24 dstNodeID, uint64 weight)
        external
        allowListOnly
    {
        edges[srcNodeID][relID][relKey] = EdgeData(dstNodeID, weight);
        emit State.EdgeSet(relID, relKey, srcNodeID, dstNodeID, weight);
    }

    function remove(bytes4 relID, uint8 relKey, bytes24 srcNodeID) external allowListOnly {
        delete edges[srcNodeID][relID][relKey];
        emit State.EdgeRemove(relID, relKey, srcNodeID);
    }

    function get(bytes4 relID, uint8 relKey, bytes24 srcNodeID)
        external
        view
        returns (bytes24 dstNodeID, uint64 weight)
    {
        EdgeData storage e = edges[srcNodeID][relID][relKey];
        return (e.dstNodeID, e.weight);
    }

    function annotate(bytes24 nodeID, string memory label, string memory annotationData) external allowListOnly {
        bytes32 annotationRef = keccak256(bytes(annotationData));
        annotations[nodeID][keccak256(bytes(label))] = annotationRef;
        emit State.AnnotationSet(nodeID, AnnotationKind.CALLDATA, label, annotationRef, annotationData);
    }

    function getAnnotationRef(bytes24 nodeID, string memory annotationLabel) external view returns (bytes32) {
        return annotations[nodeID][keccak256(bytes(annotationLabel))];
    }

    function setData(bytes24 nodeID, string memory label, bytes32 data) external allowListOnly {
        nodeData[nodeID][keccak256(bytes(label))] = data;
        emit State.DataSet(nodeID, label, data);
    }

    function getData(bytes24 nodeID, string memory annotationLabel) external view returns (bytes32) {
        return nodeData[nodeID][keccak256(bytes(annotationLabel))];
    }

    function registerNodeType(bytes4 kindID, string memory kindName, CompoundKeyKind keyKind) external ownerOnly {
        _registerNodeType(kindID, kindName, keyKind);
    }

    function _registerNodeType(bytes4 kindID, string memory kindName, CompoundKeyKind keyKind) internal {
        emit State.NodeTypeRegister(kindID, kindName, keyKind);
    }

    function registerEdgeType(bytes4 relID, string memory relName, WeightKind weightKind) external ownerOnly {
        _registerEdgeType(relID, relName, weightKind);
    }

    function _registerEdgeType(bytes4 relID, string memory relName, WeightKind weightKind) internal {
        emit State.EdgeTypeRegister(relID, relName, weightKind);
    }

    function authorizeContract(address addr) external ownerOnly {
        require(addr != address(0), "BaseState: Cannot authorize the zero address");
        allowlist[addr] = true;
    }

    function getStateOpsRecorder() external view returns (StateOpsRecorder) {
        return stateOpsRecorder;
    }
}
