// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IState.sol";
import "./IDispatcher.sol";
import "./IRouter.sol";
import "./IRule.sol";
import {BaseState} from "./BaseState.sol";
import {Op, StateOpsRecorder} from "./StateOpsRecorder.sol";

// BaseDispatcher implements some basic structure around registering ActionTypes
// and Rules and executing those rules in the defined order against a given State
// implementation.
//
// To use it, inherit from BaseDispatcher and then override `dispatch()` to add
// any application specific validation/authorization for who can dispatch Actions
//
// TODO:
// * need way to remove, reorder or clear the rulesets
contract BaseDispatcher is Dispatcher {
    address public owner;
    mapping(Router => bool) private trustedRouters;
    mapping(string => address) private actionAddrs;
    Rule[] private rules;
    BaseState private state;
    StateOpsRecorder private stateOpsRecorder;

    modifier ownerOnly() {
        require(msg.sender == owner, "BaseDispatcher: Sender is not the owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        // allow calling ourself
        registerRouter(Router(address(this)));
    }

    function registerRule(Rule rule) public ownerOnly returns (Rule) {
        return _registerRule(rule);
    }

    function _registerRule(Rule rule) internal returns (Rule) {
        rules.push() = rule;
        return rule;
    }

    // registerRouter(r) will implicitly trust the Context data submitted
    // by r to dispatch(action, ctx) calls.
    //
    // this is useful if there is an external contract managing authN, authZ
    // or when using a "session key" pattern like the BaseRouter.
    //
    function registerRouter(Router r) public ownerOnly {
        _registerRouter(r);
    }

    function _registerRouter(Router r) internal {
        trustedRouters[r] = true;
    }

    function registerState(State s) public ownerOnly {
        _registerState(s);
    }

    function _registerState(State s) internal {
        state = BaseState(address(s));
        stateOpsRecorder = BaseState(address(s)).getStateOpsRecorder();
    }

    function isRegisteredRouter(address r) internal view returns (bool) {
        return trustedRouters[Router(r)];
    }

    function dispatch(bytes calldata action, Context calldata ctx) public {
        // check ctx can be trusted.
        // we trust ctx built from ourself see the dispatch(action) function above that builds a full-access session for the msg.sender
        // we trust ctx built from any registered routers
        if (!isRegisteredRouter(msg.sender)) {
            revert("DispatchUntrustedSender");
        }
        for (uint256 i = 0; i < rules.length; i++) {
            rules[i].reduce(state, action, ctx);
        }
        emit ActionDispatched(
            address(ctx.sender),
            "<nonce>" // TODO: unique ids, nonces, and replay protection
        );
    }

    // dispatch from router trusted context
    function dispatch(bytes[] calldata actions, Context calldata ctx) public {
        for (uint256 i = 0; i < actions.length; i++) {
            dispatch(actions[i], ctx);
        }
    }

    function dispatch(bytes calldata action) public {
        Context memory ctx = Context({sender: msg.sender, scopes: SCOPE_FULL_ACCESS, clock: uint32(block.number)});
        this.dispatch(action, ctx);
    }

    function dispatch(bytes[] calldata actions) public {
        for (uint256 i = 0; i < actions.length; i++) {
            dispatch(actions[i]);
        }
    }

    // The following functions are expected to be used with ETH_CALL so that Ops can be gathered without any state changes

    function dispatchWithOpsRecorder(bytes calldata action, Context calldata ctx) public returns (Op[] memory) {
        uint256 fromHead = stateOpsRecorder.getHead();
        // check ctx can be trusted.
        // we trust ctx built from ourself see the dispatch(action) function above that builds a full-access session for the msg.sender
        // we trust ctx built from any registered routers
        if (!isRegisteredRouter(msg.sender)) {
            revert("DispatchUntrustedSender");
        }
        for (uint256 i = 0; i < rules.length; i++) {
            rules[i].reduce(stateOpsRecorder, action, ctx);
        }
        emit ActionDispatched(
            address(ctx.sender),
            "<nonce>" // TODO: unique ids, nonces, and replay protection
        );
        uint256 toHead = stateOpsRecorder.getHead();
        return stateOpsRecorder.getOps(fromHead, toHead);
    }

    // dispatch from router trusted context
    function dispatchWithOpsRecorder(bytes[] calldata actions, Context calldata ctx) public returns (Op[] memory) {
        uint256 fromHead = stateOpsRecorder.getHead();
        for (uint256 i = 0; i < actions.length; i++) {
            dispatchWithOpsRecorder(actions[i], ctx);
        }
        uint256 toHead = stateOpsRecorder.getHead();
        return stateOpsRecorder.getOps(fromHead, toHead);
    }

    function dispatchWithOpsRecorder(bytes calldata action) public returns (Op[] memory) {
        Context memory ctx = Context({sender: msg.sender, scopes: SCOPE_FULL_ACCESS, clock: uint32(block.number)});
        return this.dispatchWithOpsRecorder(action, ctx);
    }

    function dispatchWithOpsRecorder(bytes[] calldata actions) public returns (Op[] memory) {
        uint256 fromHead = stateOpsRecorder.getHead();
        for (uint256 i = 0; i < actions.length; i++) {
            dispatchWithOpsRecorder(actions[i]);
        }
        uint256 toHead = stateOpsRecorder.getHead();
        return stateOpsRecorder.getOps(fromHead, toHead);
    }
}
