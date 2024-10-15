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
                let bal := balanceOf(decodeAddress(0))
                returnUint(bal)
            }
            default {
                revert(0,0)
            }
            
            function balanceOf(owner)->bal{
                if iszero(owner) {
                    revertERC721InvalidOwner(owner)
                }

                bal:=sload(_mapping(_ownersSlot(),owner))
            }
            
            function decodeAddress(offset)-> v{
                v := decodeUint(offset)
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

            function returnUint(v){
                mstore(0,v)
                return(0,0x20)
            }

            function _requireOwned(tokenId) -> owner{
                owner := _ownerOf(tokenId)
                if iszero(owner) {
                    revertERC721NonexistentToken(tokenId)
                }
            }
            function ownerOf(tokenId){
               let owner := _ownerOf(tokenId)             
               returnUint(owner)
            }
            
            function _ownerOf(tokenId) -> owner{
                owner := sload(_mapping(_ownersSlot(),tokenId))                
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
            
            function selector() -> sel{
                sel := div(calldataload(0),0x100000000000000000000000000000000000000000000000000000000)
            }

            function require(condition) {
                if iszero(condition) { revert(0,0) }
            }

            function revertERC721InvalidOwner(owner){
                mstore(0,0x89c62b64)
                mstore(0x20,owner)
                revert(0x1c,0x24)
            }

            function revertERC721NonexistentToken(tokenId){
                mstore(0,0x7e273289)
                mstore(0x20,tokenId)
                revert(0x1c,0x24)
            }
        }
    }
}