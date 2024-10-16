object "ERC721"{
    code {
        //execute constructor
        datacopy(0,dataoffset("runtime"),datasize("runtime"))
        return(0,datasize("runtime"))
    }
    object "runtime" {
        code {
            /** Function Hub/Switcher/Disptacher */

            switch selector() 
            /*supportsInterface(bytes4)*/
            case 0x01ffc9a7 {
            }
            /*balanceOf(address)*/ 
            case 0x70a08231 {
                balanceOfWrapper()
            }
            /*isApprovedForAll(address, address )*/
            case 0xe985e9c5 {
                isApprovedForAllWrapper()
            }
            /**mint(address,uint256)*/ 
            case 0x40c10f19 { 
                mintWrapper() 
            }
            /*ownerOf(uint256)*/
            case 0x6352211e { 
                ownerOfWrapper() 
            }
            default { revert(0,0) }

            /** Function Wrappers / Public */
            function balanceOfWrapper(){
                let bal := _balanceOf(decodeAddress(0))
                returnUint(bal)
            }

            function mintWrapper(){
               let to := decodeAddress(0)
               let tokenId := decodeUint(1)
               _mint(to,tokenId)
            }

            function isApprovedForAllWrapper(){
                let owner := decodeAddress(0)
                let operator := decodeAddress(1)
                let approved := isApprovedForAll(owner,operator)
                if approved {
                    returnUint(1)
                }
        
                returnUint(0)
            }

            function ownerOfWrapper(){
                let tokenId :=decodeUint(0)
                let owner := _requireOwned(tokenId)
                returnUint(owner)
            }
            
            /** Internal Function  */
            function _mint(to,tokenId){
                if iszero(to){
                    revertERC721InvalidReceiver(0x0)
                }

                let oldOwner := _update(to,tokenId,0x0)
                if notZeroAddress(oldOwner) {
                    revertERC721InvalidSender(0x0)
                }
            }

            function _balanceOf(owner)->bal{
                if iszero(owner) {
                    revertERC721InvalidOwner(owner)
                }

                bal := sload(_mapping(owner,_ownersSlot()))
            }

            function _requireOwned(tokenId) -> owner{
                owner := _ownerOf(tokenId)
                if iszero(owner) {
                    revertERC721NonexistentToken(tokenId)
                }
            }

            function _ownerOf(tokenId) -> owner{
                owner := sload(_mapping(tokenId,_ownersSlot()))                
            }

            function _update(to,tokenId,auth) -> from{
                from := _ownerOf(tokenId)
                if notZeroAddress(auth){
                    _checkAuthorized(from,auth,tokenId)
                }

                if notZeroAddress(from){
                    _approve(0x0,tokenId,0x0,0x0)
                    let slot := _mapping(from,_balancesSlot())
                    let prev := sload(slot)
                    sstore(slot, sub(prev,1))
                }

                if notZeroAddress(to){
                    let slot := _mapping(to,_balancesSlot())
                    let prev := sload(slot)
                    sstore(slot,add(prev,1))
                }

                let slot := _mapping(tokenId,_ownersSlot())
                sstore(slot,to)
                emitTransfer(from,to,tokenId)
                //return
            }
      
            function _approve(to, tokenId, auth, emit){
                if or(emit, notZeroAddress(auth)){
                    let owner := _requireOwned(tokenId)

                    if and(notZeroAddress(auth), and(not(eq(owner,auth)), not(isApprovedForAll(owner,auth)))){
                        revertERC721InvalidApprover(auth)
                    }

                    if emit {
                        emitApproval(owner,to,tokenId)
                    }
                }

                let slot := _mapping(tokenId,_tokenApprovalsSlot())
                sstore(slot,to)
            }

            function _checkAuthorized(owner,spender,tokenId){
                if iszero(_isAuthorized(owner,spender,tokenId)){
                    if iszero(owner){
                        revertERC721NonexistentToken(tokenId)
                    }

                    revertERC721InsufficientApproval(spender,tokenId)   
                }
            }

            function _isAuthorized(owner,spender,tokenId) -> authorized{
                let nonZeroSpender := notZeroAddress(spender)
                let selfAuth := eq(owner, spender)
                let approvedForAll := isApprovedForAll(owner, spender)
                let spenderApproved := eq(_getApproved(tokenId), spender)
                authorized := and(nonZeroSpender, or(selfAuth,or(approvedForAll, spenderApproved)))

            }

            function isApprovedForAll(owner, operator) -> approved {
                let slot := _mapping(operator,_mapping(owner,_operatorApprovalsSlot()))
                approved := sload(slot)
            }

            function _getApproved(tokenId) -> approved {
                let slot := _mapping(tokenId,_tokenApprovalsSlot())
                approved := sload(slot)
            }

            /** Contract Layout  */
            
            function _nameSlot() ->s { s:=0 }
            function _symbolSlot() ->s { s:=1 }
            function _ownersSlot() ->s { s:=2 }
            function _balancesSlot() ->s { s:=3 }
            function _tokenApprovalsSlot() ->s { s:=4 }
            function _operatorApprovalsSlot() ->s { s:=5 } 

             /** Contract Events  */
            
            function emitTransfer(from,to,tokenId){
                let sigHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                
                emitEvent(sigHash,from,to,tokenId)
            }
            function emitApproval(owner,to,tokenId){
                let sigHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925

                emitEvent(sigHash,owner,to,tokenId)
            }
            function emitEvent(sigHash, indexed1, indexed2, nonIndexed){
                mstore(0,nonIndexed)
                log3(0,0x20,sigHash,indexed1,indexed2)
            }

            /** Contract Errors  */

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

            function revertERC721InsufficientApproval(spender,tokenId){
                mstore(0,0x177e802f)
                mstore(0x20,spender)
                mstore(0x40,tokenId)
                revert(0x1c,0x44)
            }

            function revertERC721InvalidApprover(approver){
                mstore(0,0xa9fbf51f)
                mstore(0x20,approver)
                revert(0x1c,0x24)
            }

            function revertERC721InvalidReceiver(receiver){
                mstore(0,0x64a0ae92)
                mstore(0x20,receiver)
                revert(0x1c,0x24)
            }
            function revertERC721InvalidSender(sender){
                mstore(0,0x73c6ac6e)
                mstore(0x20,sender)
                revert(0x1c,0x24)
            }
                        
            /** Utilities  */
            function _mapping(key,slot) -> s {
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

            function ne(a,b) -> bool {
                bool := true
                if eq(a,b){
                    bool := false
                }
            } 

            function notZeroAddress(addr) -> b {
                b := true
                if eq(addr,0x0){
                    b := false
                }
            }

        }
    }
}