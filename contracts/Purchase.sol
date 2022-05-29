// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Purchase {
    uint256 public value;
    address payable public seller;
    address payable public buyer;

    enum State {
        Created,
        Locked,
        Released,
        Inactive
    }
    // state variable has default value of first member `State.Created`
    State public state;

    modifier condition(bool condition_) {
        require(condition_, "The condition is not true");
        _;
    }

    /// Only buyer can call this function
    error OnlyBuyer();
    /// Only seller can call this function
    error OnlySeller();
    /// The function cannot be called in current state
    error InvalidState();
    /// The provided value has to be even
    error ValueNotEven();

    modifier onlyBuyer() {
        // if(msg.sender != buyer)
        //     revert OnlyBuyer();
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlySeller() {
        // if(msg.sender != seller)
        //     revert OnlySeller();
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier inState(State state_) {
        // if (state!=state_)
        //     revert InvalidState();
        require(
            state == state_,
            "The function cannot be called in current state"
        );
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemRecieved();
    event SellerRefunded();

    // Ensure msg.value is an even number because division will truncate if its an odd number
    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        // if ( (2*value)!=msg.value)
        //     revert ValueNotEven();
        require((2 * value) == msg.value, "The provided ether has to be even");
    }

    /// Abort the purchase and reclaim ether. Can only be called by seller before contract is locked
    function abort() external onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        // Transfer here can be called directly as its re-entry safe as the state is changed
        seller.transfer(address(this).balance);
    }

    /// Confirm the purchase as buyer. Transaction has to include `2*value` ether.
    /// The ether will be locked until confirmReceived is called
    function confirmPurchase()
        external
        payable
        inState(State.Created)
        condition(msg.value == (2 * value))
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    /// Confirm that buyer recevied the item. This will release locked ether
    function confirmReceived() external onlyBuyer inState(State.Locked) {
        emit ItemRecieved();
        state = State.Released;
        buyer.transfer(value);
    }

    /// This function refunds the seller i.e pays back the locked funds of seller
    function refundSeller() external onlySeller inState(State.Released) {
        emit SellerRefunded();
        state = State.Inactive;
        seller.transfer(3 * value);
    }
}
