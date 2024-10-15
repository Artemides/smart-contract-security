object "ERC721"{
    code {
        //execute constructor
        datacopy(0,dataoffset("runtime"),datasize("runtime"))
        return(0,datasize("runtime"))
    }
    object "runtime" {
        code {
            
            switch selector() 
            case 0x01ffc9a7 /*supportsInterface(bytes4 interfaceId)*/{
                // 
            }
            case 0x70a08231 /*balanceOf(address owner)*/{
                balanceOf(decodeAddress(0))
            }
            
            function balanceOf(owner)->balance{
                balance:=sload(_mapping(_ownersSlot(),owner))
                mstore(0,balance)
                return(0,0)
            }
            
            function decodeAddress(offset)-> v{
                v := decodeUint(offset);
                if iszero(iszero(and(v,not(0xffffffffffffffffffffffffffffffffffffffff)))){
                    revert(0,0)
                }            
            }

            function decodeUint(offset) -> v {
                let pos := add(4,mul(offset,0x20))
                if lt(calldatasize(),add(pos,0x20)){
                    revert(0,0)
                }

                v:=calldataload(pos)
            }
            function _nameSlot() ->s { s:=0}
            function _symbolSlot() ->s { s:=1}
            function _ownersSlot() ->s { s:=2}
            function _balancesSlot() ->s { s:=3}
            function _tokenApprovalsSlot() ->s { s:=4}
            function _operatorApprovalsSlot() ->s { s:=5}

            function _mapping(slot,key) -> s {
                //keccak256 p n
                mstore(0,key)
                mstore(0x20,slot)
                s := keccak256(0,0x40)
            }
            
            function selector() -> selector{
                selector := div(calldataload(0),0x100000000000000000000000000000000000000000000000000000000)
            }
        }
    }
}